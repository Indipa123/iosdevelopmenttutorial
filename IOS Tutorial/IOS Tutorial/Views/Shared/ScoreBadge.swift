import SwiftUI

/// Compact stat pill used across the quiz header, result screens and the Stats tab.
struct ScoreBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.58))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
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

#Preview {
    HStack(spacing: 10) {
        ScoreBadge(title: "SCORE", value: "47", color: .yellow)
        ScoreBadge(title: "STREAK", value: "5", color: .green)
        ScoreBadge(title: "BEST", value: "112", color: .orange)
    }
    .padding()
    .background(Color.black)
}
