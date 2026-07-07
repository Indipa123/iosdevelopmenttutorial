import Foundation
internal import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    var totalGames: Int { sessions.count }

    var totalScore: Int { sessions.reduce(0) { $0 + $1.score } }

    var recentSessions: [GameSession] {
        Array(sessions.sorted { $0.timestamp > $1.timestamp }.prefix(10))
    }

    func sessions(for mode: GameMode) -> [GameSession] {
        sessions.filter { $0.mode == mode }
    }

    func best(for mode: GameMode) -> Int {
        sessions(for: mode).map(\.score).max() ?? 0
    }

    func refresh() {
        sessions = GameSessionStore.load()
    }

    func resetAll() {
        GameSessionStore.clear()
        refresh()
    }
}
