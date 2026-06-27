import SwiftUI
import AudioToolbox
import UIKit

enum LightLevel: Int, CaseIterable {
    case L1 = 1, L2, L3, L4

    var cardCount: Int {
        switch self {
        case .L1: return 3
        case .L2: return 4
        case .L3: return 6
        case .L4: return 9
        }
    }

    var columns: Int {
        switch self {
        case .L1: return 3
        case .L2: return 2
        case .L3: return 3
        case .L4: return 3
        }
    }

    var litWindow: TimeInterval {
        switch self {
        case .L1: return 1.5
        case .L2: return 1.2
        case .L3: return 1.0
        case .L4: return 0.8
        }
    }

    var simultaneousLit: Int {
        self == .L4 ? 2 : 1
    }

    var glowColor: Color {
        switch self {
        case .L1: return Color(red: 0.30, green: 1.00, blue: 0.45)
        case .L2: return Color(red: 0.30, green: 0.65, blue: 1.00)
        case .L3: return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .L4: return Color(red: 1.00, green: 0.30, blue: 0.35)
        }
    }

    var displayName: String { "L\(rawValue)" }

    var pointsPerHit: Int { rawValue * 10 }

    static func forProgress(_ progress: Double) -> LightLevel {
        switch progress {
        case ..<0.25: return .L1
        case ..<0.50: return .L2
        case ..<0.75: return .L3
        default: return .L4
        }
    }
}

struct LightCard: Identifiable {
    let id = UUID()
    var isLit: Bool = false
    var bumpScale: CGFloat = 1.0
}

struct LightItUpView: View {
    @AppStorage("lightItUpHighScore") private var highScore = 0
    @AppStorage("lightItUpRoundLength") private var roundLength = 60

    @State private var cards: [LightCard] = []
    @State private var score = 0
    @State private var lives = 3
    @State private var timeRemaining: Int = 60
    @State private var currentLevel: LightLevel = .L1
    @State private var gameOver = false
    @State private var hasStarted = false
    @State private var showSettings = false

    @State private var showLevelUpFlash = false
    @State private var levelUpText = ""
    @State private var penaltyFlashOpacity: Double = 0
    @State private var showConfetti = false
    @State private var celebrateScale: CGFloat = 0.1
    @State private var trophyRotation: Double = 0
    @State private var displayedFinalScore = 0
    @State private var scoreBump: CGFloat = 1.0
    @State private var heartScale: [CGFloat] = [1, 1, 1]
    @State private var heartShake: [CGFloat] = [0, 0, 0]
    @State private var timeBarShakeOpacity: Double = 0
    @State private var levelFlashScale: CGFloat = 0.5

    @State private var gameTask: Task<Void, Never>?
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            WallpaperBackground()

            VStack(spacing: 18) {
                statsHeader

                levelBadge

                timeBar

                Spacer(minLength: 8)

                cardGrid
                    .padding(.horizontal, 12)

                Spacer(minLength: 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 18)
            .padding(.horizontal, 18)

            Color.red
                .opacity(penaltyFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)

            if showLevelUpFlash {
                levelUpOverlay
                    .transition(.opacity)
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if !hasStarted && !gameOver {
                startOverlay
            } else if gameOver {
                gameOverOverlay
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            VignetteOverlay()
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .disabled(hasStarted && !gameOver)
                .opacity(hasStarted && !gameOver ? 0.3 : 1)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(roundLength: $roundLength)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            resetGame()
        }
        .onDisappear {
            gameTask?.cancel()
            countdownTask?.cancel()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 12) {
            stat(title: "SCORE", value: "\(score)", color: .yellow, scale: scoreBump)
            stat(title: "TIME", value: "\(timeRemaining)", color: timeRemaining <= 5 ? .red : .white)
            livesView
        }
    }

    private func stat(title: String, value: String, color: Color, scale: CGFloat = 1.0) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .tracking(1.2)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 6)
                .scaleEffect(scale)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var livesView: some View {
        VStack(spacing: 2) {
            Text("LIVES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .tracking(1.2)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < lives ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(i < lives ? .red : .white.opacity(0.3))
                        .shadow(color: i < lives ? .red.opacity(0.6) : .clear, radius: 6)
                        .scaleEffect(heartScale[i])
                        .offset(x: heartShake[i])
                }
            }
            .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Level Badge

    private var levelBadge: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(currentLevel.glowColor)
                .frame(width: 10, height: 10)
                .shadow(color: currentLevel.glowColor, radius: 6)

            Text("LEVEL \(currentLevel.rawValue)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2.5)

            Text("·")
                .foregroundColor(.white.opacity(0.5))

            Text("\(String(format: "%.1f", currentLevel.litWindow))s")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(currentLevel.glowColor.opacity(0.65), lineWidth: 1.5)
                )
        )
        .shadow(color: currentLevel.glowColor.opacity(0.5), radius: 12)
    }

    // MARK: - Time Bar

    private var timeBar: some View {
        GeometryReader { geo in
            let progress = max(0, min(1, Double(timeRemaining) / Double(roundLength)))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: timeRemaining <= 5 ? [.red, .orange] : [.cyan, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
                    .shadow(color: (timeRemaining <= 5 ? Color.red : Color.cyan).opacity(0.7), radius: 6)
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Card Grid

    private var cardGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 14),
            count: currentLevel.columns
        )

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                LightCardView(
                    card: card,
                    glowColor: currentLevel.glowColor
                ) {
                    tapCard(card)
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: currentLevel)
    }

    // MARK: - Start Overlay

    private var startOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .cyan.opacity(0.8), radius: 14)

                Text("LIGHT IT UP")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .tracking(3)

                Text("Tap lit cards before they fade.\nGrid grows. Window shrinks.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Button {
                    startGame()
                } label: {
                    Text("START  \(roundLength)s")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                        .padding(.vertical, 14)
                        .frame(width: 240)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(18)
                        .shadow(color: .blue.opacity(0.7), radius: 14)
                }

                if highScore > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("HIGH SCORE  \(highScore)")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .tracking(1.5)
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
            .shadow(color: .black.opacity(0.5), radius: 30)
        }
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(lives == 0 ? "OUT OF LIVES" : "TIME'S UP")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .red.opacity(0.6), radius: 12)
                    .tracking(2)

                Text("FINAL SCORE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .tracking(2)

                Text("\(displayedFinalScore)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.8), radius: 18)
                    .contentTransition(.numericText())

                if score == highScore && score > 0 {
                    VStack(spacing: 10) {
                        Text("🏆")
                            .font(.system(size: 70))
                            .rotationEffect(.degrees(trophyRotation))
                            .scaleEffect(celebrateScale)
                            .shadow(color: .yellow.opacity(0.9), radius: 20)

                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: .green.opacity(0.7), radius: 10)
                            .scaleEffect(celebrateScale)
                            .tracking(1.5)
                    }
                }

                Text("HIGH SCORE  \(highScore)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)

                Button {
                    resetGame()
                    startGame()
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                        .padding(.vertical, 13)
                        .frame(width: 220)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.7), radius: 14)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
            .shadow(color: .black.opacity(0.5), radius: 30)
        }
    }

    // MARK: - Level Up Overlay

    private var levelUpOverlay: some View {
        ZStack {
            currentLevel.glowColor.opacity(0.35)
                .ignoresSafeArea()
                .blendMode(.screen)

            VStack(spacing: 8) {
                Text(levelUpText)
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: currentLevel.glowColor, radius: 28)
                    .tracking(6)

                Text(levelDescription(for: currentLevel))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(3)
            }
            .scaleEffect(levelFlashScale)
        }
    }

    private func levelDescription(for level: LightLevel) -> String {
        switch level {
        case .L1: return "3 CARDS  ·  1.5s WINDOW"
        case .L2: return "4 CARDS  ·  1.2s WINDOW"
        case .L3: return "6 CARDS  ·  1.0s WINDOW"
        case .L4: return "9 CARDS  ·  0.8s  ·  ×2 LIT"
        }
    }

    // MARK: - Game Lifecycle

    private func resetGame() {
        gameTask?.cancel()
        countdownTask?.cancel()
        gameTask = nil
        countdownTask = nil

        score = 0
        lives = 3
        timeRemaining = roundLength
        currentLevel = .L1
        gameOver = false
        hasStarted = false
        showConfetti = false
        celebrateScale = 0.1
        trophyRotation = 0
        displayedFinalScore = 0
        heartScale = [1, 1, 1]
        heartShake = [0, 0, 0]

        cards = (0..<LightLevel.L1.cardCount).map { _ in LightCard() }
    }

    private func startGame() {
        guard !hasStarted else { return }
        hasStarted = true

        AudioServicesPlaySystemSound(1057)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        startCountdown()
        startGameLoop()
    }

    private func startCountdown() {
        countdownTask = Task { @MainActor in
            while !Task.isCancelled && !gameOver && timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled || gameOver { break }
                timeRemaining -= 1
                if timeRemaining <= 5 && timeRemaining > 0 {
                    AudioServicesPlaySystemSound(1103)
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
                            }
                        }
                    }
                }
                firstCycle = false

                if gameOver { break }

                try? await Task.sleep(nanoseconds: 120_000_000)
                if Task.isCancelled || gameOver { continue }

                let toLight = currentLevel.simultaneousLit
                let dimIndices = cards.indices.filter { !cards[$0].isLit }.shuffled()
                for index in dimIndices.prefix(toLight) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                        cards[index].isLit = true
                    }
                }
                AudioServicesPlaySystemSound(1306)

                let waitNanos = UInt64(max(0.1, currentLevel.litWindow - 0.12) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: waitNanos)
            }
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
                for i in cards.indices { cards[i].isLit = false }
            }
        }

        triggerLevelUpFlash(newLevel)
    }

    private func triggerLevelUpFlash(_ level: LightLevel) {
        levelUpText = "LEVEL \(level.rawValue)"
        AudioServicesPlaySystemSound(1025)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        levelFlashScale = 0.5
        withAnimation(.easeIn(duration: 0.15)) {
            showLevelUpFlash = true
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
            levelFlashScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.35)) {
                showLevelUpFlash = false
            }
        }
    }

    // MARK: - Tap Handling

    private func tapCard(_ card: LightCard) {
        guard hasStarted, !gameOver else { return }
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                cards[index].isLit = false
                cards[index].bumpScale = 1.25
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.12)) {
                cards[index].bumpScale = 1.0
            }

            score += currentLevel.pointsPerHit
            AudioServicesPlaySystemSound(1104)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            bumpScore()
        } else {
            loseLife()
            AudioServicesPlaySystemSound(1053)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            flashPenalty()

            withAnimation(.linear(duration: 0.05).repeatCount(4, autoreverses: true)) {
                cards[index].bumpScale = 0.88
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
                cards[index].bumpScale = 1.0
            }
        }
    }

    // MARK: - Effects

    private func loseLife() {
        guard lives > 0 else { return }
        lives -= 1
        let heartIndex = lives

        if heartIndex >= 0 && heartIndex < heartScale.count {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.35)) {
                heartScale[heartIndex] = 1.6
            }
            withAnimation(.linear(duration: 0.05).repeatCount(4, autoreverses: true)) {
                heartShake[heartIndex] = 8
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.18)) {
                heartScale[heartIndex] = 1.0
                heartShake[heartIndex] = 0
            }
        }

        if lives == 0 {
            endGame()
        }
    }

    private func bumpScore() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            scoreBump = 1.25
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.12)) {
            scoreBump = 1.0
        }
    }

    private func flashPenalty() {
        withAnimation(.easeOut(duration: 0.1)) {
            penaltyFlashOpacity = 0.5
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.1)) {
            penaltyFlashOpacity = 0
        }
    }

    private func endGame() {
        guard !gameOver else { return }
        gameOver = true
        gameTask?.cancel()
        countdownTask?.cancel()

        if score > highScore {
            highScore = score
            triggerWinCelebration()
        } else {
            playLosingSound()
        }

        animateFinalScoreCountUp()
    }

    private func animateFinalScoreCountUp() {
        displayedFinalScore = 0
        let target = score
        guard target > 0 else { return }
        let steps = min(target, 30)
        let interval = 0.9 / Double(steps)
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation {
                    displayedFinalScore = target * step / steps
                }
                if step % 5 == 0 {
                    AudioServicesPlaySystemSound(1104)
                }
            }
        }
    }

    private func triggerWinCelebration() {
        AudioServicesPlaySystemSound(1025)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.easeIn(duration: 0.2)) {
            showConfetti = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
            celebrateScale = 1.2
            trophyRotation = 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                celebrateScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            AudioServicesPlaySystemSound(1057)
        }
    }

    private func playLosingSound() {
        AudioServicesPlaySystemSound(1006)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Card View

struct LightCardView: View {
    let card: LightCard
    let glowColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        card.isLit
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [glowColor, glowColor.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                card.isLit ? Color.white.opacity(0.5) : Color.white.opacity(0.12),
                                lineWidth: card.isLit ? 2 : 1
                            )
                    )

                if card.isLit {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.18))
                        .padding(8)
                        .blur(radius: 4)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(card.isLit ? 1.04 * card.bumpScale : 0.94 * card.bumpScale)
            .shadow(
                color: card.isLit ? glowColor.opacity(0.85) : .clear,
                radius: card.isLit ? 22 : 0
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: card.isLit)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @Binding var roundLength: Int
    @Environment(\.dismiss) private var dismiss

    private let options = [30, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.indigo.opacity(0.7), Color.blue.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 22) {
                    Text("ROUND LENGTH")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .tracking(2.5)

                    HStack(spacing: 10) {
                        ForEach(options, id: \.self) { value in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    roundLength = value
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(value)")
                                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    Text("seconds")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .tracking(1.5)
                                        .opacity(0.75)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            roundLength == value
                                                ? AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [.blue, .purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            roundLength == value ? Color.white.opacity(0.5) : Color.white.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: roundLength == value ? .blue.opacity(0.6) : .clear,
                                    radius: 14
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Round length affects how each level's window of time stretches across the game.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Light It Up") {
    NavigationStack {
        LightItUpView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Settings") {
    SettingsSheet(roundLength: .constant(60))
}
