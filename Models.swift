import Foundation

struct AppUser: Codable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let password: String
}

/// Одна строка в раздаче: ник, закуп, выкуп.
struct PlayerRow: Codable, Identifiable, Hashable {
    let id: UUID
    let nickname: String
    let buyIn: Double
    let cashOut: Double

    var result: Double {
        cashOut - buyIn
    }
}

/// Целиком одна «игра за столом»: несколько игроков, залитая одним действием.
struct GameSession: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let rows: [PlayerRow]
    /// Учтена ли эта игра в расчёте переводов.
    var isSettled: Bool

    enum CodingKeys: String, CodingKey {
        case id, date, rows, isSettled
    }

    init(id: UUID, date: Date, rows: [PlayerRow], isSettled: Bool = false) {
        self.id = id
        self.date = date
        self.rows = rows
        self.isSettled = isSettled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        rows = try c.decode([PlayerRow].self, forKey: .rows)
        isSettled = try c.decodeIfPresent(Bool.self, forKey: .isSettled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(rows, forKey: .rows)
        try c.encode(isSettled, forKey: .isSettled)
    }
}

/// Один перевод при расчёте: `from` отдаёт `to` сумму `amount` у.е.
struct SettlementTransfer: Codable, Identifiable, Hashable {
    let id: UUID
    let fromNickname: String
    let toNickname: String
    let amount: Double
}

/// Сохранённый расчёт по набору игр.
struct SettlementRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let transfers: [SettlementTransfer]
    let settledSessionIds: [UUID]
}

/// Форматирование сумм в у.е. для UI.
enum UEFormat {
    static func string(for value: Double) -> String {
        let number = value.formatted(
            .number
                .precision(.fractionLength(0...2))
                .grouping(.automatic)
        )
        return "\(number) у.е."
    }
}

struct StatsSummary {
    /// Сколько раз залили полную игру (сессию).
    let sessionsCount: Int
    /// Сколько всего строк игроков по всем сессиям.
    let playerRowsCount: Int
    let totalResult: Double
    let averageResultPerRow: Double
    let maxWin: Double
    let maxLoss: Double
}
