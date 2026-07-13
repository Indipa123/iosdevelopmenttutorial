import SwiftUI

struct StatsTab: View {
    @StateObject private var viewModel = StatsViewModel()
    @Environment(\.horizontalSizeClass) private var hSize

    private var isRegularWidth: Bool { hSize == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 640 : 360 }
    private var outerHorizontalPadding: CGFloat { isRegularWidth ? 32 : 24 }
    private var compactColumns: [GridItem] {
        [GridItem(.flexible(minimum: 0), spacing: 10)]
    }
    private var twoColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 0), spacing: 10),
            GridItem(.flexible(minimum: 0), spacing: 10)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WallpaperBackground()

                GeometryReader { proxy in
                    let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            if viewModel.sessions.isEmpty {
                                emptyState
                            } else {
                                totals
                                personalBests
                                recentGames
                            }
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.horizontal, outerHorizontalPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 110)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                VignetteOverlay()
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 44, weight: .heavy))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.7), radius: 12)

            Text("NO GAMES YET")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)

            Text("Complete a game and its session will show up here.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(panel)
        .padding(.top, 60)
    }

    private var totals: some View {
        LazyVGrid(columns: twoColumns, spacing: 10) {
            ScoreBadge(title: "GAMES PLAYED", value: "\(viewModel.totalGames)", color: .cyan)
            ScoreBadge(title: "TOTAL SCORE", value: "\(viewModel.totalScore)", color: .yellow)
        }
    }

    private var personalBests: some View {
        LazyVGrid(columns: isRegularWidth ? twoColumns : compactColumns, spacing: 10) {
            ForEach(GameMode.allCases) { mode in
                ScoreBadge(
                    title: mode.displayName.uppercased(),
                    value: "\(viewModel.best(for: mode))",
                    color: mode.accent
                )
            }
        }
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT GAMES")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .tracking(3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ForEach(viewModel.recentSessions) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.mode.icon)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(session.mode.accent)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(session.mode.accent.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.mode.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(session.score)")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(session.mode.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(panel)
            }
        }
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

#Preview {
    StatsTab()
        .preferredColorScheme(.dark)
}
