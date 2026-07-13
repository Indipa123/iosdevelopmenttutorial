import SwiftUI
import AudioToolbox
import UIKit

struct LightItUpView: View {
    @StateObject private var viewModel = LightItUpViewModel()

    @AppStorage("lightItUpRoundLength") private var roundLength = 60

    @Environment(\.horizontalSizeClass) private var hSize

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
    @State private var levelFlashScale: CGFloat = 0.5

    private var isRegularWidth: Bool { hSize == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 640 : 360 }
    private var outerHorizontalPadding: CGFloat { isRegularWidth ? 28 : 16 }

    var body: some View {
        ZStack {
            WallpaperBackground()

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                VStack(spacing: 18) {
                    statsHeader

                    levelBadge

                    timeBar

                    Spacer(minLength: 8)

                    cardGrid
                        .padding(.horizontal, 12)

                    Spacer(minLength: 8)
                }
                .frame(width: contentWidth)
                .clipped()
                .padding(.top, 8)
                .padding(.bottom, 18)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }

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

            if !viewModel.hasStarted && !viewModel.gameOver {
                startOverlay
            } else if viewModel.gameOver {
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
                .disabled(viewModel.hasStarted && !viewModel.gameOver)
                .opacity(viewModel.hasStarted && !viewModel.gameOver ? 0.3 : 1)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(roundLength: $roundLength)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.onEvent = handleEvent
            resetGame()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var statsHeader: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 8),
            count: 3
        )

        return LazyVGrid(columns: columns, spacing: 8) {
            stat(title: "SCORE", value: "\(viewModel.score)", color: .yellow, scale: scoreBump)
            stat(title: "TIME", value: "\(viewModel.timeRemaining)", color: viewModel.timeRemaining <= 5 ? .red : .white)
            livesView
        }
    }

    private func stat(title: String, value: String, color: Color, scale: CGFloat = 1.0) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 6)
                .scaleEffect(scale)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(i < viewModel.lives ? .red : .white.opacity(0.3))
                        .shadow(color: i < viewModel.lives ? .red.opacity(0.6) : .clear, radius: 6)
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

    private var levelBadge: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(viewModel.currentLevel.glowColor)
                .frame(width: 10, height: 10)
                .shadow(color: viewModel.currentLevel.glowColor, radius: 6)

            Text("LEVEL \(viewModel.currentLevel.number)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2.5)

            Text("·")
                .foregroundColor(.white.opacity(0.5))

            Text("\(String(format: "%.1f", viewModel.currentLevel.litWindow))s")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(viewModel.currentLevel.glowColor.opacity(0.65), lineWidth: 1.5)
                )
        )
        .shadow(color: viewModel.currentLevel.glowColor.opacity(0.5), radius: 12)
    }

    private var timeBar: some View {
        GeometryReader { geo in
            let progress = max(0, min(1, Double(viewModel.timeRemaining) / Double(roundLength)))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: viewModel.timeRemaining <= 5 ? [.red, .orange] : [.cyan, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
                    .shadow(color: (viewModel.timeRemaining <= 5 ? Color.red : Color.cyan).opacity(0.7), radius: 6)
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }

    private var cardGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 14),
            count: viewModel.currentLevel.columns
        )

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(viewModel.cards) { card in
                LightCardView(
                    card: card,
                    glowColor: viewModel.currentLevel.glowColor
                ) {
                    viewModel.tapCard(card)
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.currentLevel)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: viewModel.cards.map(\.id))
    }

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

                Text("Tap lit cards before they fade.\nCards move. Later levels require order.")
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

                if viewModel.highScore > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("HIGH SCORE  \(viewModel.highScore)")
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

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(viewModel.lives == 0 ? "OUT OF LIVES" : "TIME'S UP")
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

                if viewModel.isNewHighScore {
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

                Text("HIGH SCORE  \(viewModel.highScore)")
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

    private var levelUpOverlay: some View {
        ZStack {
            viewModel.currentLevel.glowColor.opacity(0.35)
                .ignoresSafeArea()
                .blendMode(.screen)

            VStack(spacing: 8) {
                Text(levelUpText)
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: viewModel.currentLevel.glowColor, radius: 28)
                    .tracking(6)

                Text(levelDescription(for: viewModel.currentLevel))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(3)
            }
            .scaleEffect(levelFlashScale)
        }
    }

    private func levelDescription(for level: LightLevel) -> String {
        level.ruleSummary.uppercased()
    }

    private func resetGame() {
        viewModel.resetGame(roundLength: roundLength)

        showConfetti = false
        celebrateScale = 0.1
        trophyRotation = 0
        displayedFinalScore = 0
        heartScale = [1, 1, 1]
        heartShake = [0, 0, 0]
    }

    private func startGame() {
        AudioServicesPlaySystemSound(1057)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        viewModel.startGame(roundLength: roundLength)
    }

    private func handleEvent(_ event: LightItUpViewModel.GameEvent) {
        switch event {
        case .cardsLit:
            AudioServicesPlaySystemSound(1306)

        case .correctTap:
            AudioServicesPlaySystemSound(1104)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            bumpScore()

        case .wrongTap:
            AudioServicesPlaySystemSound(1053)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            flashPenalty()

        case .lifeLost(let heartIndex):
            animateHeartLoss(at: heartIndex)

        case .levelUp(let level):
            triggerLevelUpFlash(level)

        case .timeWarning:
            AudioServicesPlaySystemSound(1103)

        case .gameEnded(let isNewHighScore):
            if isNewHighScore {
                triggerWinCelebration()
            } else {
                playLosingSound()
            }
            animateFinalScoreCountUp()
        }
    }

    private func triggerLevelUpFlash(_ level: LightLevel) {
        levelUpText = "LEVEL \(level.number)"
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

    private func animateHeartLoss(at heartIndex: Int) {
        guard heartIndex >= 0 && heartIndex < heartScale.count else { return }

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

    private func animateFinalScoreCountUp() {
        displayedFinalScore = 0
        let target = viewModel.score
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

                    if let targetOrder = card.targetOrder {
                        Text("\(targetOrder)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.45), radius: 5)
                    }
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
