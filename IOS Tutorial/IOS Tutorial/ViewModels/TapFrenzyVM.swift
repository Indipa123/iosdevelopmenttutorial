import Foundation
internal import Combine

@MainActor
final class TapFrenzyViewModel: ObservableObject {

    enum TapOutcome: Equatable {
        case bonus(earned: Int, comboMilestone: Bool)
        case penalty
    }

    enum TickOutcome: Equatable {
        case running
        case warning
        case ended(isNewHighScore: Bool)
    }

    @Published private(set) var score = 0
    @Published private(set) var timeRemaining = 10
    @Published private(set) var gameOver = false
    @Published private(set) var comboMultiplier = 1
    @Published private(set) var isBonusColour = true
    @Published private(set) var highScore: Int

    private var lastTapTime: Date?
    private let highScoreKey = "highScore"

    init() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
    }

    var isNewHighScore: Bool { score == highScore && score > 0 }

    func tick() -> TickOutcome {
        guard !gameOver else { return .running }

        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        if timeRemaining == 0 {
            return .ended(isNewHighScore: endGame())
        }

        return timeRemaining <= 3 ? .warning : .running
    }

    func toggleBonusColour() {
        guard !gameOver else { return }
        isBonusColour.toggle()
    }

    func registerTap() -> TapOutcome {
        let currentTime = Date()

        if let lastTap = lastTapTime, currentTime.timeIntervalSince(lastTap) <= 0.5 {
            comboMultiplier += 1
        } else {
            comboMultiplier = 1
        }

        lastTapTime = currentTime

        if isBonusColour {
            let earned = comboMultiplier * 2
            score += earned
            return .bonus(
                earned: earned,
                comboMilestone: comboMultiplier == 5 || comboMultiplier == 10
            )
        } else {
            score = max(0, score - 1)
            return .penalty
        }
    }

    func restart() {
        score = 0
        timeRemaining = 10
        gameOver = false
        comboMultiplier = 1
        lastTapTime = nil
        isBonusColour = true
    }

    private func endGame() -> Bool {
        gameOver = true

        GameSessionStore.append(GameSession(
            mode: .tapFrenzy,
            score: score,
            latitude: LocationService.shared.latitude,
            longitude: LocationService.shared.longitude
        ))

        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: highScoreKey)
            return true
        }
        return false
    }
}
