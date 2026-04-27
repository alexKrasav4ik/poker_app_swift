import Foundation
import Combine

final class GameStore: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private let sessionsKey = "poker_app_sessions_v2"
    private let legacyGamesKey = "poker_app_games"

    init() {
        loadSessions()
    }

    /// Заливает одну игру целиком: массив (ник, закуп, выкуп).
    func addSession(playerRows: [(nickname: String, buyIn: Double, cashOut: Double)]) {
        let rows: [PlayerRow] = playerRows.map {
            PlayerRow(id: UUID(), nickname: $0.nickname, buyIn: $0.buyIn, cashOut: $0.cashOut)
        }

        let session = GameSession(id: UUID(), date: Date(), rows: rows)
        sessions.append(session)
        sessions.sort { $0.date > $1.date }
        saveSessions()
    }

    var stats: StatsSummary {
        let allRows = sessions.flatMap(\.rows)
        guard !allRows.isEmpty else {
            return StatsSummary(
                sessionsCount: sessions.count,
                playerRowsCount: 0,
                totalResult: 0,
                averageResultPerRow: 0,
                maxWin: 0,
                maxLoss: 0
            )
        }

        let results = allRows.map(\.result)
        let total = results.reduce(0, +)
        let average = total / Double(results.count)

        return StatsSummary(
            sessionsCount: sessions.count,
            playerRowsCount: allRows.count,
            totalResult: total,
            averageResultPerRow: average,
            maxWin: results.max() ?? 0,
            maxLoss: results.min() ?? 0
        )
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([GameSession].self, from: data) {
            sessions = decoded.sorted { $0.date > $1.date }
            return
        }

        if let migrated = loadLegacyGamesAsSessions() {
            sessions = migrated
            saveSessions()
            UserDefaults.standard.removeObject(forKey: legacyGamesKey)
            return
        }

        sessions = []
    }

    private func loadLegacyGamesAsSessions() -> [GameSession]? {
        guard let data = UserDefaults.standard.data(forKey: legacyGamesKey),
              let legacy = try? JSONDecoder().decode([LegacyGameEntry].self, from: data),
              !legacy.isEmpty
        else {
            return nil
        }

        return legacy.map { old in
            let row = PlayerRow(
                id: old.id,
                nickname: old.nickname,
                buyIn: old.buyIn,
                cashOut: old.cashOut
            )
            return GameSession(id: old.id, date: old.date, rows: [row])
        }
        .sorted { $0.date > $1.date }
    }
}

/// Старый формат одной строки = одна «игра» — только для миграции из UserDefaults.
private struct LegacyGameEntry: Codable {
    let id: UUID
    let nickname: String
    let buyIn: Double
    let cashOut: Double
    let date: Date
}
