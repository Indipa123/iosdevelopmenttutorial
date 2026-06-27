import SwiftUI
import AudioToolbox
import UIKit
internal import Combine

struct ContentView: View {

    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var gameOver = false

    @State private var comboMultiplier = 1
    @State private var lastTapTime: Date?

    @State private var isBonusColour = true

    @AppStorage("highScore") private var highScore = 0

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

    let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let colourTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            WallpaperBackground()

            if gameOver {
                gameOverView
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                gameView
                    .transition(.opacity)
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startContinuousAnimations()
        }
        .onReceive(gameTimer) { _ in
            if !gameOver {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    if timeRemaining <= 3 && timeRemaining > 0 {
                        AudioServicesPlaySystemSound(1103)
                        pulseTimerWarning()
                    }
                }

                if timeRemaining == 0 {
                    endGame()
                }
            }
        }
        .onReceive(colourTimer) { _ in
            if !gameOver {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isBonusColour.toggle()
                }
            }
        }
    }

    var gameView: some View {
        VStack(spacing: 28) {

            Text("TAP FRENZY")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .cyan.opacity(0.7), radius: 12)
                .tracking(2)

            HStack {
                statCard(title: "SCORE", value: "\(score)", color: .yellow, scale: scoreBump)

                Spacer()

                statCard(title: "TIME", value: "\(timeRemaining)", color: timeRemaining <= 3 ? .red : .white, scale: timerPulseScale)
            }
            .padding(.horizontal, 32)

            Text("COMBO  ×\(comboMultiplier)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule().stroke(comboMultiplier >= 3 ? Color.orange : Color.white.opacity(0.3), lineWidth: 2)
                        )
                )
                .scaleEffect(comboBump)
                .shadow(color: comboMultiplier >= 3 ? .orange.opacity(0.8) : .clear, radius: 12)
                .overlay(alignment: .trailing) {
                    if comboMultiplier >= 3 {
                        Text("🔥")
                            .font(.title2)
                            .offset(x: 26)
                    }
                }

            Text(isBonusColour ? "GREEN = BONUS" : "GREY = PENALTY")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .tracking(1.5)

            tapButton

            Text("HIGH SCORE: \(highScore)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .tracking(1)
        }
        .padding()
    }

    func statCard(title: String, value: String, color: Color, scale: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)

            Text(value)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 8)
                .scaleEffect(scale)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    var tapButton: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        isBonusColour ? Color.green.opacity(0.5) : Color.gray.opacity(0.4),
                        lineWidth: 3
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseRingScale + CGFloat(i) * 0.15)
                    .opacity(pulseRingOpacity - Double(i) * 0.2)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: isBonusColour
                            ? [.green, .green.opacity(0.7)]
                            : [.gray, .gray.opacity(0.6)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 130
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: isBonusColour ? .green.opacity(0.9) : .gray.opacity(0.6), radius: 30)
                .scaleEffect(auraPulse)

            Button {
                tapButtonPressed()
            } label: {
                Text("TAP")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6)
                    .frame(width: 220, height: 220)
                    .contentShape(Circle())
            }
            .scaleEffect(tapScale)
            .offset(x: penaltyShake)

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
                    LinearGradient(colors: [.white, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .red.opacity(0.6), radius: 14)
                .tracking(2)

            Text("FINAL SCORE")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .tracking(2)

            Text("\(displayedFinalScore)")
                .font(.system(size: 90, weight: .heavy, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.8), radius: 18)
                .contentTransition(.numericText())

            if score == highScore && score > 0 {
                VStack(spacing: 12) {
                    Text("🏆")
                        .font(.system(size: 84))
                        .rotationEffect(.degrees(trophyRotation))
                        .scaleEffect(celebrateScale)
                        .shadow(color: .yellow.opacity(0.9), radius: 22)

                    Text("NEW HIGH SCORE!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: .green.opacity(0.7), radius: 10)
                        .scaleEffect(celebrateScale)
                        .tracking(1.5)
                }
            }

            Text("HIGH SCORE: \(highScore)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .tracking(1)

            Button {
                restartGame()
            } label: {
                Text("PLAY AGAIN")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding()
                    .frame(width: 240)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(18)
                    .shadow(color: .blue.opacity(0.7), radius: 14)
            }
        }
        .padding()
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

    func tapButtonPressed() {
        let currentTime = Date()

        if let lastTap = lastTapTime {
            let difference = currentTime.timeIntervalSince(lastTap)

            if difference <= 0.5 {
                comboMultiplier += 1
            } else {
                comboMultiplier = 1
            }
        } else {
            comboMultiplier = 1
        }

        lastTapTime = currentTime

        if isBonusColour {
            let earned = comboMultiplier * 2
            score += earned

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

            if comboMultiplier == 5 || comboMultiplier == 10 {
                AudioServicesPlaySystemSound(1025)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            score -= 1
            if score < 0 { score = 0 }

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

    func endGame() {
        gameOver = true

        if score > highScore {
            highScore = score
            triggerWinCelebration()
        } else {
            playLosingSound()
        }

        animateFinalScoreCountUp()
    }

    func animateFinalScoreCountUp() {
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
            score = 0
            timeRemaining = 10
            gameOver = false
            comboMultiplier = 1
            lastTapTime = nil
            isBonusColour = true
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
            .foregroundColor(item.isBonus ? .yellow : .red)
            .shadow(color: (item.isBonus ? Color.yellow : Color.red).opacity(0.8), radius: 8)
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
        ContentView()
    }
    .preferredColorScheme(.dark)
}
