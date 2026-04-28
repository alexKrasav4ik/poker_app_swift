import Foundation

/// Сводит нетто по игрокам к списку переводов «кто кому сколько».
enum SettlementEngine {
    private static let epsilon = 0.005

    static func normalizeNickname(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Агрегирует результаты по нику (без учёта регистра и лишних пробелов).
    static func aggregateBalances(rows: [PlayerRow]) -> [(normKey: String, displayName: String, net: Double)] {
        var totals: [String: Double] = [:]
        var display: [String: String] = [:]

        for row in rows {
            let key = normalizeNickname(row.nickname)
            guard !key.isEmpty else { continue }
            totals[key, default: 0] += row.result
            if display[key] == nil {
                display[key] = row.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return totals.map { key, net in
            (normKey: key, displayName: display[key] ?? key, net: round2(net))
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Жертвователи (отрицательный нетто) платят тем, у кого положительный нетто.
    static func buildTransfers(balances: [(displayName: String, net: Double)]) -> [SettlementTransfer] {
        var debtors: [(name: String, amount: Double)] = []
        var creditors: [(name: String, amount: Double)] = []

        for b in balances {
            if b.net < -epsilon {
                debtors.append((name: b.displayName, amount: round2(-b.net)))
            } else if b.net > epsilon {
                creditors.append((name: b.displayName, amount: round2(b.net)))
            }
        }

        debtors.sort { $0.amount > $1.amount }
        creditors.sort { $0.amount > $1.amount }

        var di = 0
        var ci = 0
        var result: [SettlementTransfer] = []

        while di < debtors.count && ci < creditors.count {
            var d = debtors[di]
            var c = creditors[ci]
            let pay = min(d.amount, c.amount)
            if pay > epsilon {
                result.append(
                    SettlementTransfer(
                        id: UUID(),
                        fromNickname: d.name,
                        toNickname: c.name,
                        amount: round2(pay)
                    )
                )
            }
            d.amount = round2(d.amount - pay)
            c.amount = round2(c.amount - pay)
            debtors[di] = d
            creditors[ci] = c
            if d.amount <= epsilon { di += 1 }
            if c.amount <= epsilon { ci += 1 }
        }

        return result
    }

    private static func round2(_ x: Double) -> Double {
        (x * 100).rounded() / 100
    }
}
