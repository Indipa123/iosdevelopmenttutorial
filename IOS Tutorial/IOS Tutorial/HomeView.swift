import SwiftUI
internal import Combine

struct HomeView: View {
    @AppStorage("highScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    @State private var titleGlow = false
    @State private var appear = false

    private var isRegularWidth: Bool { hSize == .regular }
    private var isCompactHeight: Bool { vSize == .compact }
    private var useTwoColumnGames: Bool { isRegularWidth || isCompactHeight }

    private var contentMaxWidth: CGFloat { isRegularWidth ? 860 : .infinity }
    private var titleSize: CGFloat { isRegularWidth ? 78 : 50 }
    private var titleTracking: CGFloat { isRegularWidth ? 10 : 5 }
    private var taglineSize: CGFloat { isRegularWidth ? 16 : 13 }
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
        .preferredColorScheme(.dark)
        .tint(.cyan)
    }

    private var homeContent: some View {
        ZStack {
            WallpaperBackground()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: sectionSpacing) {
                        header
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -16)
                            .padding(.top, topPadding)

                        statsSummary
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -8)

                        sectionLabel("GAMES")
                            .opacity(appear ? 1 : 0)
                            .padding(.top, 2)

                        gameCardsLayout
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 26)

                        footerHint
                            .opacity(appear ? 0.65 : 0)
                            .padding(.top, 6)
                            .padding(.bottom, 18)
                    }
                    .padding(.horizontal, outerHorizontalPadding)
                    .frame(maxWidth: contentMaxWidth, alignment: .center)
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
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                titleGlow = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: .green, radius: 5)
                Text("READY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(2)
            }

            Text("ARCADE")
                .font(.system(size: titleSize, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan, .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .cyan.opacity(titleGlow ? 0.9 : 0.4), radius: titleGlow ? 22 : 12)
                .tracking(titleTracking)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Text("Two games. One arena.")
                .font(.system(size: taglineSize, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsSummary: some View {
        HStack(spacing: 10) {
            SummaryStat(
                label: "TAP FRENZY",
                value: "\(tapFrenzyHighScore)",
                icon: "bolt.fill",
                color: .green
            )

            SummaryStat(
                label: "LIGHT IT UP",
                value: "\(lightItUpHighScore)",
                icon: "square.grid.3x3.fill",
                color: .blue
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var gameCardsLayout: some View {
        let columns: [GridItem] = useTwoColumnGames
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 16) {
            NavigationLink {
                ContentView()
            } label: {
                GameFeatureCard(
                    title: "TAP FRENZY",
                    tagline: "Tap fast. Beat the clock.",
                    description: "10-second rush. Stack combos.",
                    accent: .green,
                    gradient: [.green, .mint, .cyan],
                    highScore: tapFrenzyHighScore,
                    previewHeight: previewHeight,
                    preview: AnyView(TapFrenzyPreview())
                )
            }
            .buttonStyle(ModeCardButtonStyle())

            NavigationLink {
                LightItUpView()
            } label: {
                GameFeatureCard(
                    title: "LIGHT IT UP",
                    tagline: "Tap the lit card.",
                    description: "Grid grows. Window shrinks.",
                    accent: .blue,
                    gradient: [.blue, .indigo, .purple],
                    highScore: lightItUpHighScore,
                    previewHeight: previewHeight,
                    preview: AnyView(LightItUpPreview())
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
                .foregroundColor(.white.opacity(0.55))
                .tracking(3)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var footerHint: some View {
        VStack(spacing: 5) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
            Text("TAP A GAME TO PLAY")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary Stat Card

struct SummaryStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 5)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 3) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(value)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundColor(color)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Game Feature Card

struct GameFeatureCard: View {
    let title: String
    let tagline: String
    let description: String
    let accent: Color
    let gradient: [Color]
    let highScore: Int
    let previewHeight: CGFloat
    let preview: AnyView

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.35) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                preview
            }
            .frame(height: previewHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 22
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(tagline)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(highScore)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(accent.opacity(0.18))
                            .overlay(
                                Capsule().stroke(accent.opacity(0.5), lineWidth: 1)
                            )
                    )
                }

                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .heavy))
                    Text("PLAY NOW")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(2)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .heavy))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: accent.opacity(0.65), radius: 10)
                .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [accent.opacity(0.55), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: accent.opacity(0.3), radius: 18, y: 6)
    }
}

// MARK: - Tap Frenzy Mini Preview

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
                        .stroke(Color.green.opacity(0.55), lineWidth: 1.5)
                        .frame(width: circleSize, height: circleSize)
                        .scaleEffect(ringScale + CGFloat(i) * 0.12)
                        .opacity(ringOpacity - Double(i) * 0.18)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green, .green.opacity(0.6)],
                            center: .center,
                            startRadius: 4,
                            endRadius: circleSize * 0.6
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: .green.opacity(0.75), radius: circleSize * 0.2)
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

// MARK: - Light It Up Mini Preview

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

// MARK: - Button Style

struct ModeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview("iPhone") {
    HomeView()
}

#Preview("iPad", traits: .landscapeLeft) {
    HomeView()
}
