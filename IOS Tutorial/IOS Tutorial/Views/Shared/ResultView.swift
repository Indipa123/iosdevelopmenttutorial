import SwiftUI

/// Shared end-of-round panel with a ShareLink.
/// TODO (Week 4 ShareLink step): adopt this on each game's game-over screen.
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
                .shadow(color: .yellow.opacity(0.75), radius: 16)

            Text("GAME OVER")
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)

            Text("\(score)")
                .font(.system(size: 76, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.75), radius: 18)

            if isNewHighScore {
                Text("NEW HIGH SCORE!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .tracking(1.5)
            }

            ScoreBadge(title: "BEST", value: "\(highScore)", color: accent)

            ShareLink(item: shareMessage) {
                Label("SHARE SCORE", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        LinearGradient(colors: [accent, accent.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: accent.opacity(0.55), radius: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
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
        .background(Color.black)
}
