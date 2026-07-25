import SwiftUI
import AudioToolbox
import UIKit
internal import Combine

struct TapFrenzyView: View {

    @StateObject private var viewModel = TapFrenzyViewModel()

    @Environment(\.horizontalSizeClass) private var hSize

    @State private var showConfetti = false
    @State private var celebrateScale: CGFloat = 0.1
    @State private var trophyRotation: Double = 0

    @State private var tapScale: CGFloat = 1.0
    @State private var penaltyShake: CGFloat = 0
    @State private var penaltyFlashOpacity: Double = 0

    @State private var pulseRingScale: CGFloat = 1.0
    @State private var pulseRingOpacity: Double = 0.7
    @State private var auraPulse: CGFloat = 1.0

    @State private var scoreBump: CGFloat = 1.0
    @State private var comboBump: CGFloat = 1.0
    @State private var timerPulseScale: CGFloat = 1.0

    @State private var displayedFinalScore = 0

    @State private var floatingScores: [FloatingScore] = []

    private var isRegularWidth: Bool { hSize == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 560 : 360 }
    private var outerHorizontalPadding: CGFloat { isRegularWidth ? 28 : 16 }

    let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let colourTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GameBackdrop(accent: AppTheme.mint)

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                Group {
                    if viewModel.gameOver {
                        gameOverView
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    } else {
                        gameView
                            .transition(.opacity)
                    }
                }
                .frame(width: contentWidth)
                .clipped()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            Color.red
                .opacity(penaltyFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)

            VignetteOverlay()
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            startContinuousAnimations()
        }
        .onReceive(gameTimer) { _ in
            handleTick()
        }
        .onReceive(colourTimer) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                viewModel.toggleBonusColour()
            }
        }
    }

    var gameView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("10 SECOND SPRINT", systemImage: "bolt.fill")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.mint)
                        .tracking(1.3)

                    Text("Tap Frenzy")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("BEST")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                        .tracking(1.4)
                    Text(viewModel.highScore.formatted())
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(AppTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 10) {
                statCard(title: "SCORE", value: "\(viewModel.score)", color: AppTheme.amber, scale: scoreBump)
                statCard(title: "SECONDS", value: "\(viewModel.timeRemaining)", color: viewModel.timeRemaining <= 3 ? .red : AppTheme.ink, scale: timerPulseScale)
            }

            HStack(spacing: 10) {
                Label("COMBO ×\(viewModel.comboMultiplier)", systemImage: viewModel.comboMultiplier >= 3 ? "flame.fill" : "bolt.circle.fill")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.comboMultiplier >= 3 ? AppTheme.coral : AppTheme.ink)
                    .scaleEffect(comboBump)

                Spacer()

                Text(viewModel.isBonusColour ? "TARGET LIVE" : "TARGET PAUSED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.isBonusColour ? AppTheme.mint : AppTheme.secondaryInk)
                    .tracking(1.1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.80), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            tapStage

            Label(
                viewModel.isBonusColour ? "Tap the mint target to score" : "Wait for the target to turn mint",
                systemImage: viewModel.isBonusColour ? "hand.tap.fill" : "pause.circle.fill"
            )
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.secondaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.72), in: Capsule())
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 16)
    }

    private var tapStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.surface.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(viewModel.isBonusColour ? AppTheme.mint.opacity(0.28) : AppTheme.line, lineWidth: 1)
                }

            VStack(spacing: 8) {
                Text(viewModel.isBonusColour ? "GO" : "HOLD")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.isBonusColour ? AppTheme.mint : AppTheme.secondaryInk)
                    .tracking(3)
                    .padding(.top, 18)

                tapButton
                    .frame(height: 230)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 284)
        .shadow(color: AppTheme.shadow.opacity(0.08), radius: 18, y: 8)
    }

    func statCard(title: String, value: String, color: Color, scale: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.7))
                .tracking(1.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(value)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 8)
                .scaleEffect(scale)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .appSurface(cornerRadius: 16)
    }

    var tapButton: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        viewModel.isBonusColour ? AppTheme.mint.opacity(0.26) : Color.gray.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 190, height: 190)
                    .scaleEffect(pulseRingScale + CGFloat(i) * 0.15)
                    .opacity(pulseRingOpacity - Double(i) * 0.2)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: viewModel.isBonusColour
                            ? [AppTheme.mint, AppTheme.mint.opacity(0.7)]
                            : [.gray, .gray.opacity(0.6)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 130
                    )
                )
                .frame(width: 190, height: 190)
                .shadow(color: AppTheme.shadow.opacity(viewModel.isBonusColour ? 0.14 : 0.10), radius: 16, y: 8)
                .scaleEffect(auraPulse)

            Button {
                tapButtonPressed()
            } label: {
                Text("TAP")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.ink.opacity(0.35), radius: 4)
                    .frame(width: 190, height: 190)
                    .contentShape(Circle())
            }
            .scaleEffect(tapScale)
            .offset(x: penaltyShake)
            .accessibilityLabel(viewModel.isBonusColour ? "Bonus tap target" : "Penalty tap target")
            .accessibilityValue("Score \(viewModel.score), combo \(viewModel.comboMultiplier), \(viewModel.timeRemaining) seconds remaining")
            .accessibilityHint(viewModel.isBonusColour ? "Double tap to earn points." : "Do not tap until the target turns green.")

            ForEach(floatingScores) { item in
                FloatingScoreText(item: item)
            }
        }
    }

    var gameOverView: some View {
        VStack(spacing: 22) {

            Text("GAME OVER")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [AppTheme.ink, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .red.opacity(0.6), radius: 14)
                .tracking(2)

            Text("FINAL SCORE")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.75))
                .tracking(2)

            Text("\(displayedFinalScore)")
                .font(.system(size: 90, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.amber)
                .shadow(color: AppTheme.amber.opacity(0.8), radius: 18)
                .contentTransition(.numericText())

            if viewModel.isNewHighScore {
                VStack(spacing: 12) {
                    Text("🏆")
                        .font(.system(size: 84))
                        .rotationEffect(.degrees(trophyRotation))
                        .scaleEffect(celebrateScale)
                        .shadow(color: AppTheme.amber.opacity(0.9), radius: 22)

                    Text("NEW HIGH SCORE!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [AppTheme.mint, AppTheme.amber], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: AppTheme.mint.opacity(0.7), radius: 10)
                        .scaleEffect(celebrateScale)
                        .tracking(1.5)
                }
            }

            Text("HIGH SCORE: \(viewModel.highScore)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.ink)
                .tracking(1)

            Button {
                restartGame()
            } label: {
                Text("PLAY AGAIN")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.5)
                    .padding()
                    .frame(width: 240)
                    .background(
                        LinearGradient(colors: [AppTheme.primary, AppTheme.primary], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(18)
                    .shadow(color: AppTheme.primary.opacity(0.7), radius: 14)
            }
        }
        .padding(26)
        .appSurface(cornerRadius: 30)
    }

    func startContinuousAnimations() {
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseRingScale = 1.4
            pulseRingOpacity = 0
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            auraPulse = 1.05
        }
    }

    func handleTick() {
        switch viewModel.tick() {
        case .running:
            break

        case .warning:
            AudioServicesPlaySystemSound(1103)
            pulseTimerWarning()

        case .ended(let isNewHighScore):
            if isNewHighScore {
                triggerWinCelebration()
            } else {
                playLosingSound()
            }
            animateFinalScoreCountUp()
        }
    }

    func tapButtonPressed() {
        switch viewModel.registerTap() {
        case .bonus(let earned, let comboMilestone):
            AudioServicesPlaySystemSound(1104)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            spawnFloatingScore(value: earned, isBonus: true)
            bumpScore()
            bumpCombo()

            withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
                tapScale = 1.18
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(0.08)) {
                tapScale = 1.0
            }

            if comboMilestone {
                AudioServicesPlaySystemSound(1025)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

        case .penalty:
            AudioServicesPlaySystemSound(1053)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

            spawnFloatingScore(value: -1, isBonus: false)
            flashPenalty()

            withAnimation(.linear(duration: 0.05).repeatCount(4, autoreverses: true)) {
                penaltyShake = 14
            }
            withAnimation(.linear(duration: 0.05).delay(0.2)) {
                penaltyShake = 0
            }
        }
    }

    func bumpScore() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            scoreBump = 1.25
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.12)) {
            scoreBump = 1.0
        }
    }

    func bumpCombo() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            comboBump = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.12)) {
            comboBump = 1.0
        }
    }

    func pulseTimerWarning() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            timerPulseScale = 1.35
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.15)) {
            timerPulseScale = 1.0
        }
    }

    func flashPenalty() {
        withAnimation(.easeOut(duration: 0.1)) {
            penaltyFlashOpacity = 0.55
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.1)) {
            penaltyFlashOpacity = 0
        }
    }

    func spawnFloatingScore(value: Int, isBonus: Bool) {
        let item = FloatingScore(
            value: value,
            isBonus: isBonus,
            offsetX: CGFloat.random(in: -50...50)
        )
        floatingScores.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            floatingScores.removeAll { $0.id == item.id }
        }
    }

    func animateFinalScoreCountUp() {
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

    func triggerWinCelebration() {
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

    func playLosingSound() {
        AudioServicesPlaySystemSound(1006)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func restartGame() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            viewModel.restart()
            showConfetti = false
            celebrateScale = 0.1
            trophyRotation = 0
            tapScale = 1.0
            penaltyShake = 0
            displayedFinalScore = 0
            floatingScores = []
        }
    }
}

struct FloatingScore: Identifiable {
    let id = UUID()
    let value: Int
    let isBonus: Bool
    let offsetX: CGFloat
}

struct FloatingScoreText: View {
    let item: FloatingScore
    @State private var animate = false

    var body: some View {
        Text(item.isBonus ? "+\(item.value)" : "\(item.value)")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .foregroundColor(item.isBonus ? AppTheme.amber : .red)
            .shadow(color: (item.isBonus ? AppTheme.amber : Color.red).opacity(0.8), radius: 8)
            .offset(x: item.offsetX, y: animate ? -160 : -40)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 1.4 : 0.6)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animate = true
                }
            }
    }
}

#Preview {
    NavigationStack {
        TapFrenzyView()
    }
    .preferredColorScheme(.light)
}
