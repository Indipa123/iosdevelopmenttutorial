import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.0, blue: 0.28),
                    Color(red: 0.10, green: 0.15, blue: 0.55),
                    Color(red: 0.0, green: 0.55, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<4) { i in
                Capsule()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 60, height: 1600)
                    .rotationEffect(.degrees(35))
                    .offset(x: CGFloat(i - 2) * 220, y: 0)
                    .blur(radius: 22)
            }

            RadialGradient(
                colors: [.green.opacity(0.55), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 480
            )

            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.green.opacity(0.45 - Double(i) * 0.12), lineWidth: 10)
                    .frame(width: CGFloat(660 + i * 120))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 1.0, blue: 0.5),
                            Color(red: 0.0, green: 0.7, blue: 0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 560)
                .shadow(color: .green.opacity(0.9), radius: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.55), lineWidth: 12)
                        .frame(width: 540)
                )

            Text("TAP")
                .font(.system(size: 230, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
                .tracking(6)

            Group {
                Image(systemName: "sparkle")
                    .font(.system(size: 110, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow, radius: 22)
                    .offset(x: -340, y: -340)

                Image(systemName: "sparkle")
                    .font(.system(size: 80, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow, radius: 18)
                    .offset(x: 360, y: -310)

                Image(systemName: "sparkle")
                    .font(.system(size: 90, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow, radius: 20)
                    .offset(x: 370, y: 360)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 22)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -360, y: 330)
            }
        }
        .frame(width: 1024, height: 1024)
        .background(Color.black)
        .clipped()
    }
}

#Preview("App Icon 1024", traits: .fixedLayout(width: 1024, height: 1024)) {
    AppIconView()
}

#Preview("App Icon Thumbnail") {
    AppIconView()
        .scaleEffect(0.2)
        .frame(width: 220, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 48))
}
