import SwiftUI

struct ResultView: View {
    let gameTitle: String
    let score: Int
    let highScore: Int
    let isNewHighScore: Bool
    let accent: Color
    let onPlayAgain: () -> Void

    private var shareMessage: String {
        "I just scored \(score) on \(gameTitle) — beat that!"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 54, weight: .heavy))
                .foregroundColor(.yellow)
                .background(AppTheme.amber.opacity(0.12), in: Circle())

            Text("GAME OVER")
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.ink)
                .tracking(2)

            Text("\(score)")
                .font(.system(size: 76, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.amber)

            if isNewHighScore {
                Text("NEW HIGH SCORE!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.mint, AppTheme.amber], startPoint: .leading, endPoint: .trailing)
                    )
                    .tracking(1.5)
            }

            ScoreBadge(title: "BEST", value: "\(highScore)", color: accent)

            ShareLink(item: shareMessage) {
                Label("SHARE SCORE", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.5)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .appSurface(cornerRadius: 16)
            }
            .buttonStyle(.plain)

            Button {
                onPlayAgain()
            } label: {
                Label("PLAY AGAIN", systemImage: "arrow.clockwise")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [accent, accent.opacity(0.78)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .appSurface(cornerRadius: 28)
    }
}

#Preview {
    ResultView(
        gameTitle: "Quiz Rush",
        score: 47,
        highScore: 112,
        isNewHighScore: false,
        accent: .orange
    ) {}
        .padding(24)
        .background(AppTheme.canvas)
}
