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
