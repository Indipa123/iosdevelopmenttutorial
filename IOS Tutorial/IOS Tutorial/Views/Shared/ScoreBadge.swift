import SwiftUI

struct ScoreBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
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
        .appSurface(cornerRadius: 14)
    }
}

#Preview {
    HStack(spacing: 10) {
        ScoreBadge(title: "SCORE", value: "47", color: .yellow)
        ScoreBadge(title: "STREAK", value: "5", color: .green)
        ScoreBadge(title: "BEST", value: "112", color: .orange)
    }
    .padding()
    .background(AppTheme.canvas)
}
