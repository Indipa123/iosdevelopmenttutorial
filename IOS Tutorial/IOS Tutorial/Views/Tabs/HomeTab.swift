import SwiftUI
internal import Combine

struct HomeTab: View {
    @AppStorage("highScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0
    @AppStorage("playerDisplayName") private var playerDisplayName = "Player One"
    @AppStorage("playerAvatar") private var playerAvatar = PlayerAvatar.aria.rawValue
    @AppStorage("playerPhotoData") private var playerPhotoData = Data()
    @AppStorage("playerUsesCustomPhoto") private var playerUsesCustomPhoto = false

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    @State private var appear = false

    private var isRegularWidth: Bool { hSize == .regular }
    private var isCompactHeight: Bool { vSize == .compact }
    private var useTwoColumnGames: Bool { isRegularWidth || isCompactHeight }

    private var contentMaxWidth: CGFloat { isRegularWidth ? 860 : 360 }
    private var titleSize: CGFloat { isRegularWidth ? 62 : 42 }
    private var titleTracking: CGFloat { isRegularWidth ? 2 : 1 }
    private var taglineSize: CGFloat { isRegularWidth ? 17 : 14 }
    private var previewHeight: CGFloat { isRegularWidth ? 150 : 120 }
    private var sectionSpacing: CGFloat { isRegularWidth ? 26 : 18 }
    private var outerHorizontalPadding: CGFloat { isRegularWidth ? 32 : 18 }
    private var topPadding: CGFloat { isCompactHeight ? 10 : 24 }

    var body: some View {
        NavigationStack {
            homeContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
        .tint(AppTheme.primary)
    }

    private var homeContent: some View {
        ZStack {
            WallpaperBackground()

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: sectionSpacing) {
                        header
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -16)
                            .padding(.top, topPadding)

                        bestScoresPanel
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -8)

                        sectionLabel("CHOOSE A GAME")
                            .opacity(appear ? 1 : 0)
                            .padding(.top, 2)

                        gameCardsLayout
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 26)

                        Text("Your next high score is one tap away.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.secondaryInk)
                            .opacity(appear ? 1 : 0)
                            .padding(.top, 2)
                            .padding(.bottom, 110)
                    }
                    .frame(width: contentWidth, alignment: .center)
                    .clipped()
                    .padding(.horizontal, outerHorizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            VignetteOverlay()
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                appear = true
            }
        }
    }

    private var header: some View {
        NavigationLink {
            TapFrenzyView()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 9) {
                        PlayerAvatarImage(
                            avatarRawValue: playerAvatar,
                            photoData: playerPhotoData,
                            usesCustomPhoto: playerUsesCustomPhoto,
                            size: 32
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("TODAY'S QUICK PLAY")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .tracking(1.1)
                                .foregroundColor(AppTheme.mint)
                            Text("Hey, \(playerDisplayName.isEmpty ? "Player" : playerDisplayName)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.secondaryInk)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.primary.opacity(0.10), in: Circle())
                }

                Text("Play your way")
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .tracking(titleTracking)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(AppTheme.mint)
                    Text("Start with a 10-second Tap Frenzy warm-up.")
                        .font(.system(size: taglineSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                    Spacer(minLength: 0)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [AppTheme.surface, AppTheme.mint.opacity(0.10), AppTheme.primary.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(AppTheme.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: AppTheme.primary.opacity(0.08), radius: 20, y: 8)
        }
        .buttonStyle(ModeCardButtonStyle())
    }

    private var bestScoresPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("BEST SCORES")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                        .tracking(2)
                    Text("Personal records")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                }

                Spacer()

                Image(systemName: "trophy.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.amber)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.amber.opacity(0.12), in: Circle())
            }

            HStack(spacing: 8) {
                BestScoreTile(
                    title: "FRENZY",
                    value: tapFrenzyHighScore,
                    icon: "bolt.fill",
                    color: AppTheme.mint
                )

                BestScoreTile(
                    title: "LIGHT UP",
                    value: lightItUpHighScore,
                    icon: "square.grid.3x3.fill",
                    color: AppTheme.primary
                )

                BestScoreTile(
                    title: "QUIZ",
                    value: quizRushHighScore,
                    icon: "questionmark.circle.fill",
                    color: AppTheme.coral
                )
            }
        }
        .padding(16)
        .appSurface(cornerRadius: 22)
    }

    private var gameCardsLayout: some View {
        let columns: [GridItem] = useTwoColumnGames
            ? [GridItem(.flexible(minimum: 0), spacing: 16), GridItem(.flexible(minimum: 0), spacing: 16)]
            : [GridItem(.flexible(minimum: 0))]

        return LazyVGrid(columns: columns, spacing: 16) {
            NavigationLink {
                TapFrenzyView()
            } label: {
                GameFeatureCard(
                    icon: "bolt.fill",
                    title: "Tap Frenzy",
                    subtitle: "A 10-second speed round. Build your combo.",
                    detail: "QUICK PLAY",
                    accent: AppTheme.mint,
                    highScore: tapFrenzyHighScore
                )
            }
            .buttonStyle(ModeCardButtonStyle())

            NavigationLink {
                LightItUpView()
            } label: {
                GameFeatureCard(
                    icon: "square.grid.3x3.fill",
                    title: "Light It Up",
                    subtitle: "Spot the active tile before the clock runs out.",
                    detail: "FOCUS",
                    accent: AppTheme.primary,
                    highScore: lightItUpHighScore
                )
            }
            .buttonStyle(ModeCardButtonStyle())

            NavigationLink {
                QuizRushView()
            } label: {
                GameFeatureCard(
                    icon: "questionmark.circle.fill",
                    title: "Quiz Rush",
                    subtitle: "Ten trivia questions. Keep your streak alive.",
                    detail: "TRIVIA",
                    accent: AppTheme.coral,
                    highScore: quizRushHighScore
                )
            }
            .buttonStyle(ModeCardButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: useTwoColumnGames)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .tracking(3)

            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var footerHint: some View {
        VStack(spacing: 5) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.secondaryInk)
            Text("TAP A GAME TO PLAY")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BestScoreTile: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(color.opacity(0.15))
                )

            Text(title)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text(value == 0 ? "—" : value.formatted())
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundColor(value == 0 ? AppTheme.secondaryInk.opacity(0.45) : AppTheme.ink)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.075))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct GameFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let detail: String
    let accent: Color
    let highScore: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accent.opacity(0.12))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accent.opacity(0.20), lineWidth: 1)
                    .padding(7)
                Image(systemName: icon)
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(accent)
            }
            .frame(width: 74, height: 84)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Text(detail)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(accent)
                        .tracking(1.2)
                    Circle().fill(accent.opacity(0.55)).frame(width: 3, height: 3)
                    Text("BEST \(highScore)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                }

                Text(title)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.secondaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12), in: Circle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112)
        .appSurface(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle). Best score \(highScore).")
        .accessibilityHint("Double tap to play.")
    }
}

struct TapFrenzyPreview: View {
    @State private var pulse: CGFloat = 1.0
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.7

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let circleSize = max(40, side * 0.55)
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(AppTheme.mint.opacity(0.28), lineWidth: 1.5)
                        .frame(width: circleSize, height: circleSize)
                        .scaleEffect(ringScale + CGFloat(i) * 0.12)
                        .opacity(ringOpacity - Double(i) * 0.18)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.mint.opacity(0.92), AppTheme.mint.opacity(0.72)],
                            center: .center,
                            startRadius: 4,
                            endRadius: circleSize * 0.6
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: AppTheme.shadow.opacity(0.12), radius: 12, y: 6)
                    .scaleEffect(pulse)

                Text("TAP")
                    .font(.system(size: circleSize * 0.27, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .scaleEffect(pulse)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = 1.08
            }
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                ringScale = 1.25
                ringOpacity = 0
            }
        }
    }
}

struct LightItUpPreview: View {
    @State private var litIndex: Int = 4
    @State private var colorIndex: Int = 1

    private let timer = Timer.publish(every: 0.65, on: .main, in: .common).autoconnect()

    private let colors: [Color] = [
        Color(red: 0.30, green: 1.00, blue: 0.45),
        Color(red: 0.30, green: 0.65, blue: 1.00),
        Color(red: 1.00, green: 0.80, blue: 0.20),
        Color(red: 1.00, green: 0.30, blue: 0.35)
    ]

    var body: some View {
        GeometryReader { geo in
            let available = max(80, min(geo.size.width, geo.size.height) * 0.85)
            let spacing = available * 0.06
            let cellSize = max(16, (available - spacing * 2) / 3.4)
            let glow = colors[colorIndex]

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 3),
                    spacing: spacing
                ) {
                    ForEach(0..<9, id: \.self) { i in
                        RoundedRectangle(cornerRadius: cellSize * 0.22)
                            .fill(
                                i == litIndex
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [glow, glow.opacity(0.75)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.white.opacity(0.09))
                            )
                            .frame(width: cellSize, height: cellSize)
                            .overlay(
                                RoundedRectangle(cornerRadius: cellSize * 0.22)
                                    .stroke(
                                        i == litIndex ? Color.white.opacity(0.5) : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: i == litIndex ? glow.opacity(0.8) : .clear, radius: i == litIndex ? cellSize * 0.4 : 0)
                            .scaleEffect(i == litIndex ? 1.05 : 0.94)
                            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: litIndex)
                            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: colorIndex)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(timer) { _ in
            advance()
        }
    }

    private func advance() {
        var next = Int.random(in: 0..<9)
        if next == litIndex { next = (next + 1) % 9 }
        litIndex = next
        colorIndex = (colorIndex + 1) % colors.count
    }
}

struct ModeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview("iPhone") {
    HomeTab()
}

#Preview("iPad", traits: .landscapeLeft) {
    HomeTab()
}
