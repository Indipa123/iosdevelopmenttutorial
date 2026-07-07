import SwiftUI
internal import Combine

// MARK: - Game Models

struct LightLevel: Identifiable, Equatable {
    let number: Int
    let cardCount: Int
    let columns: Int
    let litWindow: TimeInterval
    let simultaneousLit: Int
    let moveCount: Int
    let requiresOrderedTaps: Bool

    var id: Int { number }
    var displayName: String { "L\(number)" }
    var pointsPerHit: Int { number * 10 }

    var glowColor: Color {
        let colors: [Color] = [
            Color(red: 0.30, green: 1.00, blue: 0.45),
            Color(red: 0.30, green: 0.65, blue: 1.00),
            Color(red: 1.00, green: 0.80, blue: 0.20),
            Color(red: 1.00, green: 0.30, blue: 0.35),
            Color(red: 0.75, green: 0.35, blue: 1.00)
        ]
        return colors[(number - 1) % colors.count]
    }

    var ruleSummary: String {
        var parts = ["\(cardCount) cards", String(format: "%.1fs", litWindow), "\(moveCount) moves"]
        if simultaneousLit > 1 { parts.append("\(simultaneousLit) lit") }
        if requiresOrderedTaps { parts.append("ordered") }
        return parts.joined(separator: " | ")
    }

    static let all: [LightLevel] = (1...8).map { level in
        let cardCount = min(16, 3 + Int(Double(level - 1) * 1.8))
        let columns = level <= 2 ? cardCount : min(4, Int(ceil(sqrt(Double(cardCount)))))
        let litWindow = max(0.55, 1.65 - Double(level - 1) * 0.14)
        let simultaneousLit = level < 4 ? 1 : min(4, 1 + (level - 2) / 2)
        let moveCount = min(5, max(1, level))
        let requiresOrderedTaps = level >= 5

        return LightLevel(
            number: level,
            cardCount: cardCount,
            columns: columns,
            litWindow: litWindow,
            simultaneousLit: simultaneousLit,
            moveCount: moveCount,
            requiresOrderedTaps: requiresOrderedTaps
        )
    }

    static var first: LightLevel { all[0] }

    static func forProgress(_ progress: Double) -> LightLevel {
        let cappedProgress = max(0, min(progress, 0.999))
        let index = min(all.count - 1, Int(cappedProgress * Double(all.count)))
        return all[index]
    }
}

struct LightCard: Identifiable {
    let id = UUID()
    var isLit: Bool = false
    var targetOrder: Int?
    var bumpScale: CGFloat = 1.0
}

// MARK: - ViewModel

@MainActor
final class LightItUpViewModel: ObservableObject {

    /// Game-logic events the view reacts to with sounds, haptics and overlay animations.
    enum GameEvent {
        case cardsLit
        case correctTap
        case wrongTap
        case lifeLost(heartIndex: Int)
        case levelUp(LightLevel)
        case timeWarning
        case gameEnded(isNewHighScore: Bool)
    }

    @Published private(set) var cards: [LightCard] = []
    @Published private(set) var score = 0
    @Published private(set) var lives = 3
    @Published private(set) var timeRemaining = 60
    @Published private(set) var currentLevel: LightLevel = .first
    @Published private(set) var gameOver = false
    @Published private(set) var hasStarted = false
    @Published private(set) var highScore: Int

    var onEvent: ((GameEvent) -> Void)?

    private var expectedTapOrder = 1
    private var roundLength = 60
    private var gameTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let highScoreKey = "lightItUpHighScore"

    init() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
    }

    var isNewHighScore: Bool { score == highScore && score > 0 }

    // MARK: - Game Lifecycle

    func resetGame(roundLength: Int) {
        gameTask?.cancel()
        countdownTask?.cancel()
        gameTask = nil
        countdownTask = nil

        self.roundLength = roundLength
        score = 0
        lives = 3
        timeRemaining = roundLength
        currentLevel = .first
        expectedTapOrder = 1
        gameOver = false
        hasStarted = false

        cards = (0..<LightLevel.first.cardCount).map { _ in LightCard() }
    }

    func startGame(roundLength: Int) {
        guard !hasStarted else { return }
        hasStarted = true
        self.roundLength = roundLength

        startCountdown()
        startGameLoop()
    }

    func stop() {
        gameTask?.cancel()
        countdownTask?.cancel()
    }

    private func startCountdown() {
        countdownTask = Task { @MainActor in
            while !Task.isCancelled && !gameOver && timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled || gameOver { break }
                timeRemaining -= 1
                if timeRemaining <= 5 && timeRemaining > 0 {
                    onEvent?(.timeWarning)
                }
                if timeRemaining == 0 {
                    endGame()
                }
            }
        }
    }

    private func startGameLoop() {
        gameTask = Task { @MainActor in
            let totalRound = TimeInterval(roundLength)
            let startDate = Date()
            var firstCycle = true

            while !Task.isCancelled && !gameOver {
                let elapsed = Date().timeIntervalSince(startDate)
                let progress = elapsed / totalRound
                let newLevel = LightLevel.forProgress(progress)

                if newLevel != currentLevel {
                    transitionToLevel(newLevel)
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    if Task.isCancelled || gameOver { continue }
                }

                if !firstCycle {
                    let missedCount = cards.filter { $0.isLit }.count
                    if missedCount > 0 {
                        for _ in 0..<missedCount {
                            loseLife()
                        }
                        withAnimation(.easeOut(duration: 0.18)) {
                            for i in cards.indices where cards[i].isLit {
                                cards[i].isLit = false
                                cards[i].targetOrder = nil
                            }
                        }
                    }
                }
                firstCycle = false

                if gameOver { break }

                try? await Task.sleep(nanoseconds: 120_000_000)
                if Task.isCancelled || gameOver { continue }

                expectedTapOrder = 1
                let toLight = min(currentLevel.simultaneousLit, cards.count)
                let dimIndices = cards.indices.filter { !cards[$0].isLit }.shuffled()
                for (order, index) in dimIndices.prefix(toLight).enumerated() {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                        cards[index].isLit = true
                        cards[index].targetOrder = currentLevel.requiresOrderedTaps ? order + 1 : nil
                    }
                }
                onEvent?(.cardsLit)

                let litWindow = max(0.1, currentLevel.litWindow - 0.12)
                let moveCount = currentLevel.moveCount
                let segmentNanos = UInt64(litWindow / Double(moveCount + 1) * 1_000_000_000)

                for moveIndex in 0...moveCount {
                    try? await Task.sleep(nanoseconds: segmentNanos)
                    if Task.isCancelled || gameOver { break }

                    if moveIndex < moveCount {
                        moveCardsForChallenge()
                    }
                }
            }
        }
    }

    private func moveCardsForChallenge() {
        guard cards.count > 1 else { return }

        let currentOrder = cards.map(\.id)
        var movedCards = cards.shuffled()

        if movedCards.map(\.id) == currentOrder {
            movedCards.append(movedCards.removeFirst())
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            cards = movedCards
        }
    }

    private func transitionToLevel(_ newLevel: LightLevel) {
        let previousCount = currentLevel.cardCount
        currentLevel = newLevel

        if previousCount != newLevel.cardCount {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                cards = (0..<newLevel.cardCount).map { _ in LightCard() }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                for i in cards.indices {
                    cards[i].isLit = false
                    cards[i].targetOrder = nil
                }
            }
        }

        onEvent?(.levelUp(newLevel))
    }

    // MARK: - Tap Handling

    func tapCard(_ card: LightCard) {
        guard hasStarted, !gameOver else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            if currentLevel.requiresOrderedTaps && cards[index].targetOrder != expectedTapOrder {
                handleWrongTap(at: index)
                return
            }

            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                cards[index].isLit = false
                cards[index].targetOrder = nil
                cards[index].bumpScale = 1.25
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.12)) {
                cards[index].bumpScale = 1.0
            }

            if currentLevel.requiresOrderedTaps {
                expectedTapOrder += 1
            }

            score += currentLevel.pointsPerHit
            onEvent?(.correctTap)
        } else {
            handleWrongTap(at: index)
        }
    }

    private func handleWrongTap(at index: Int) {
        loseLife()
        onEvent?(.wrongTap)

        withAnimation(.linear(duration: 0.05).repeatCount(4, autoreverses: true)) {
            cards[index].bumpScale = 0.88
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
            cards[index].bumpScale = 1.0
        }
    }

    private func loseLife() {
        guard lives > 0 else { return }
        lives -= 1
        onEvent?(.lifeLost(heartIndex: lives))

        if lives == 0 {
            endGame()
        }
    }

    private func endGame() {
        guard !gameOver else { return }
        gameOver = true
        gameTask?.cancel()
        countdownTask?.cancel()

        // TODO (Week 4 Step 3): append a GameSession via GameSessionStore here.
        var isNewHigh = false
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: highScoreKey)
            isNewHigh = true
        }

        onEvent?(.gameEnded(isNewHighScore: isNewHigh))
    }
}
