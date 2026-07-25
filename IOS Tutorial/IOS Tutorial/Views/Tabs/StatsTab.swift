import SwiftUI

struct StatsTab: View {
    @StateObject private var viewModel = StatsViewModel()
    @Environment(\.horizontalSizeClass) private var hSize

    private var isRegularWidth: Bool { hSize == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 720 : 420 }
    private var horizontalPadding: CGFloat { isRegularWidth ? 32 : 20 }
    private var summaryColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isRegularWidth ? 3 : 2)
    }
    private var averageScore: Int {
        guard viewModel.totalGames > 0 else { return 0 }
        return viewModel.totalScore / viewModel.totalGames
    }
    private var topMode: GameMode? {
        GameMode.allCases.max { viewModel.best(for: $0) < viewModel.best(for: $1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WallpaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        if viewModel.sessions.isEmpty {
                            emptyState
                        } else {
                            overview
                            bests
                            recentGames
                        }
                    }
                    .frame(maxWidth: contentMaxWidth, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.canvas, for: .navigationBar)
        }
        .tint(AppTheme.primary)
        .onAppear { viewModel.refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR PROGRESS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
                .tracking(1.6)
            Text("Game stats")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.ink)
            Text(viewModel.sessions.isEmpty ? "Play a round to start building your history." : "A simple view of every round you’ve played.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 72, height: 72)
                .background(AppTheme.primary.opacity(0.10), in: Circle())
            Text("Your scorecard is ready")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.ink)
            Text("Finish any game and your scores, personal bests, and recent rounds will appear here.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .appSurface(cornerRadius: 24)
        .padding(.top, 28)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("AT A GLANCE")
            LazyVGrid(columns: summaryColumns, spacing: 12) {
                StatMetric(label: "Games played", value: "\(viewModel.totalGames)", icon: "gamecontroller.fill", color: AppTheme.primary)
                StatMetric(label: "Total score", value: "\(viewModel.totalScore)", icon: "sum", color: AppTheme.mint)
                StatMetric(label: "Average", value: "\(averageScore)", icon: "chart.line.uptrend.xyaxis", color: AppTheme.amber)
            }
        }
    }

    private var bests: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("PERSONAL BESTS")
                Spacer()
                if let topMode {
                    Text("Top: \(topMode.displayName)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.secondaryInk)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    HStack(spacing: 14) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(mode.accent)
                            .frame(width: 40, height: 40)
                            .background(mode.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.displayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.ink)
                            Text("\(viewModel.sessions(for: mode).count) rounds played")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.secondaryInk)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("BEST")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.secondaryInk)
                                .tracking(1)
                            Text("\(viewModel.best(for: mode))")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(mode.accent)
                        }
                    }
                    .padding(.vertical, 13)
                    if index < GameMode.allCases.count - 1 { Divider().overlay(AppTheme.line) }
                }
            }
            .padding(.horizontal, 16)
            .appSurface(cornerRadius: 20)
        }
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("RECENT ACTIVITY")
            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentSessions.enumerated()), id: \.element.id) { index, session in
                    HStack(spacing: 13) {
                        Image(systemName: session.mode.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(session.mode.accent)
                            .frame(width: 36, height: 36)
                            .background(session.mode.accent.opacity(0.11), in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.mode.displayName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.ink)
                            Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.secondaryInk)
                        }
                        Spacer()
                        Text("\(session.score)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.ink)
                    }
                    .padding(.vertical, 12)
                    if index < viewModel.recentSessions.count - 1 { Divider().overlay(AppTheme.line) }
                }
            }
            .padding(.horizontal, 16)
            .appSurface(cornerRadius: 20)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.secondaryInk)
            .tracking(1.6)
    }
}

private struct StatMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(value)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.ink)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appSurface(cornerRadius: 18)
    }
}

#Preview {
    StatsTab()
}
