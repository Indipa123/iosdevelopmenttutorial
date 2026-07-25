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
            GameBackdrop(accent: AppTheme.primary)

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                VStack(spacing: 14) {
                    gameHeader

                    statsHeader

                    gameBoard
                }
                .frame(width: contentWidth)
                .clipped()
                .padding(.top, 14)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.ink)
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

    private var gameHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Label("FOCUS CHALLENGE", systemImage: "circle.grid.cross.fill")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(1.2)

                Text("Light It Up")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.ink)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("PERSONAL BEST")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.secondaryInk)
                    .tracking(1.1)
                Text(viewModel.highScore == 0 ? "—" : viewModel.highScore.formatted())
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.amber)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(AppTheme.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var statsHeader: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 8),
            count: 3
        )

        return LazyVGrid(columns: columns, spacing: 8) {
            stat(title: "SCORE", value: "\(viewModel.score)", color: AppTheme.amber, scale: scoreBump)
            stat(title: "TIME", value: "\(viewModel.timeRemaining)", color: viewModel.timeRemaining <= 5 ? .red : AppTheme.ink)
            livesView
        }
    }

    private func stat(title: String, value: String, color: Color, scale: CGFloat = 1.0) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.65))
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
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.secondaryInk.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var livesView: some View {
        VStack(spacing: 2) {
            Text("LIVES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.65))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(i < viewModel.lives ? .red : AppTheme.ink.opacity(0.3))
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
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.secondaryInk.opacity(0.15), lineWidth: 1)
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
                .foregroundColor(AppTheme.ink)
                .tracking(2.5)

            Text("·")
                .foregroundColor(AppTheme.ink.opacity(0.5))

            Text("\(String(format: "%.1f", viewModel.currentLevel.litWindow))s")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.75))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.surface)
                .overlay(
                    Capsule().stroke(viewModel.currentLevel.glowColor.opacity(0.65), lineWidth: 1.5)
                )
        )
        .shadow(color: viewModel.currentLevel.glowColor.opacity(0.5), radius: 12)
    }

    private var gameBoard: some View {
        VStack(spacing: 14) {
            HStack {
                levelBadge
                Spacer(minLength: 8)
                Text(viewModel.currentLevel.requiresOrderedTaps ? "TAP IN ORDER" : "FIND THE GLOW")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.secondaryInk)
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            timeBar

            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.045))

                cardGrid
                    .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 270)
        }
        .padding(14)
        .appSurface(cornerRadius: 26)
    }

    private var timeBar: some View {
        GeometryReader { geo in
            let progress = max(0, min(1, Double(viewModel.timeRemaining) / Double(roundLength)))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.secondaryInk.opacity(0.08))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: viewModel.timeRemaining <= 5 ? [.red, AppTheme.amber] : [AppTheme.primary, AppTheme.primary, AppTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
                    .shadow(color: (viewModel.timeRemaining <= 5 ? Color.red : AppTheme.primary).opacity(0.7), radius: 6)
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }

    private var cardGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 10),
            count: viewModel.currentLevel.columns
        )

        return LazyVGrid(columns: columns, spacing: 10) {
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
            AppTheme.scrim.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 82, height: 82)
                    .background(AppTheme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 7) {
                    Text("READY TO FOCUS?")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                        .tracking(1.8)

                    Text("Light It Up")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.ink)

                    Text("Find the glowing tiles before they disappear.\nStay sharp as the board gets faster.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                HStack(spacing: 8) {
                    startRule(icon: "eye.fill", text: "Spot")
                    startRule(icon: "hand.tap.fill", text: "Tap")
                    startRule(icon: "arrow.up.right", text: "Level up")
                }

                Button {
                    startGame()
                } label: {
                    Label("START \(roundLength) SEC", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.2)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .shadow(color: AppTheme.primary.opacity(0.7), radius: 14)
                }

                if viewModel.highScore > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("HIGH SCORE  \(viewModel.highScore)")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.amber)
                    .tracking(1.5)
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(AppTheme.secondaryInk.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 22)
            .shadow(color: AppTheme.shadow.opacity(0.22), radius: 30, y: 10)
        }
    }

    private func startRule(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundColor(AppTheme.secondaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(AppTheme.primary.opacity(0.06), in: Capsule())
    }

    private var gameOverOverlay: some View {
        ZStack {
            AppTheme.scrim.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(viewModel.lives == 0 ? "OUT OF LIVES" : "TIME'S UP")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.ink, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .red.opacity(0.6), radius: 12)
                    .tracking(2)

                Text("FINAL SCORE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.ink.opacity(0.75))
                    .tracking(2)

                Text("\(displayedFinalScore)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.amber)
                    .shadow(color: AppTheme.amber.opacity(0.8), radius: 18)
                    .contentTransition(.numericText())

                if viewModel.isNewHighScore {
                    VStack(spacing: 10) {
                        Text("🏆")
                            .font(.system(size: 70))
                            .rotationEffect(.degrees(trophyRotation))
                            .scaleEffect(celebrateScale)
                            .shadow(color: AppTheme.amber.opacity(0.9), radius: 20)

                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [AppTheme.mint, AppTheme.amber], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: AppTheme.mint.opacity(0.7), radius: 10)
                            .scaleEffect(celebrateScale)
                            .tracking(1.5)
                    }
                }

                Text("HIGH SCORE  \(viewModel.highScore)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.5)

                Button {
                    resetGame()
                    startGame()
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                        .tracking(1.5)
                        .padding(.vertical, 13)
                        .frame(width: 220)
                        .background(
                            LinearGradient(colors: [AppTheme.primary, AppTheme.primary], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: AppTheme.primary.opacity(0.7), radius: 14)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(AppTheme.secondaryInk.opacity(0.2), lineWidth: 1)
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
                    .foregroundColor(AppTheme.ink)
                    .shadow(color: viewModel.currentLevel.glowColor, radius: 28)
                    .tracking(6)

                Text(levelDescription(for: viewModel.currentLevel))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink.opacity(0.9))
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
                            : AnyShapeStyle(AppTheme.secondaryInk.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                card.isLit ? AppTheme.secondaryInk.opacity(0.5) : AppTheme.secondaryInk.opacity(0.12),
                                lineWidth: card.isLit ? 2 : 1
                            )
                    )

                if card.isLit {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.secondaryInk.opacity(0.18))
                        .padding(8)
                        .blur(radius: 4)

                    if let targetOrder = card.targetOrder {
                        Text("\(targetOrder)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.ink)
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
        .accessibilityLabel(card.isLit ? "Lit target" : "Unlit card")
        .accessibilityValue(card.targetOrder.map { "Target \($0)" } ?? "")
        .accessibilityHint(card.isLit ? "Double tap to score." : "This card is not active.")
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
                    colors: [AppTheme.canvas, AppTheme.primary.opacity(0.10), AppTheme.mint.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 22) {
                    Text("ROUND LENGTH")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.ink.opacity(0.65))
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
                                .foregroundColor(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            roundLength == value
                                                ? AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [AppTheme.primary, AppTheme.primary],
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
                                            roundLength == value ? AppTheme.secondaryInk.opacity(0.5) : AppTheme.secondaryInk.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: roundLength == value ? AppTheme.primary.opacity(0.6) : .clear,
                                    radius: 14
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Round length affects how each level's window of time stretches across the game.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.ink.opacity(0.6))
                        .padding(.top, 4)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview("Light It Up") {
    NavigationStack {
        LightItUpView()
    }
    .preferredColorScheme(.light)
}

#Preview("Settings") {
    SettingsSheet(roundLength: .constant(60))
}
