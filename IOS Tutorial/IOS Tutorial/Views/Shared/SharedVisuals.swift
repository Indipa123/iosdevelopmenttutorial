import SwiftUI
import UIKit

enum AppTheme {
    static let ink = adaptive(light: .init(red: 0.10, green: 0.14, blue: 0.19, alpha: 1), dark: .init(red: 0.95, green: 0.97, blue: 1.00, alpha: 1))
    static let secondaryInk = adaptive(light: .init(red: 0.36, green: 0.42, blue: 0.49, alpha: 1), dark: .init(red: 0.66, green: 0.71, blue: 0.79, alpha: 1))
    static let canvas = adaptive(light: .init(red: 0.97, green: 0.98, blue: 1.00, alpha: 1), dark: .init(red: 0.05, green: 0.08, blue: 0.12, alpha: 1))
    static let surface = adaptive(light: .white, dark: .init(red: 0.09, green: 0.13, blue: 0.19, alpha: 1))
    static let line = adaptive(light: .init(red: 0.87, green: 0.89, blue: 0.87, alpha: 1), dark: .init(red: 0.17, green: 0.23, blue: 0.31, alpha: 1))
    static let shadow = adaptive(light: .init(red: 0.10, green: 0.14, blue: 0.19, alpha: 1), dark: .black)
    static let scrim = adaptive(light: .init(white: 0, alpha: 1), dark: .init(white: 0, alpha: 1))
    static let primary = adaptive(light: .init(red: 0.16, green: 0.35, blue: 0.83, alpha: 1), dark: .init(red: 0.45, green: 0.64, blue: 1.00, alpha: 1))
    static let mint = adaptive(light: .init(red: 0.05, green: 0.58, blue: 0.45, alpha: 1), dark: .init(red: 0.27, green: 0.82, blue: 0.64, alpha: 1))
    static let coral = adaptive(light: .init(red: 0.87, green: 0.31, blue: 0.25, alpha: 1), dark: .init(red: 1.00, green: 0.55, blue: 0.50, alpha: 1))
    static let amber = adaptive(light: .init(red: 0.82, green: 0.49, blue: 0.06, alpha: 1), dark: .init(red: 1.00, green: 0.73, blue: 0.32, alpha: 1))

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// A quiet, neutral background shared by every screen.
struct WallpaperBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.canvas, AppTheme.surface.opacity(0.86), AppTheme.canvas],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// A restrained game-specific colour wash. It is intentionally separate from
/// the shared canvas so one game's accent never leaks into another game's UI.
struct GameBackdrop: View {
    let accent: Color

    var body: some View {
        ZStack {
            WallpaperBackground()

            GeometryReader { proxy in
                Circle()
                    .fill(accent.opacity(0.10))
                    .frame(width: max(proxy.size.width, proxy.size.height) * 0.9)
                    .blur(radius: 54)
                    .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.30)

                Circle()
                    .fill(accent.opacity(0.045))
                    .frame(width: max(proxy.size.width, proxy.size.height) * 0.7)
                    .blur(radius: 42)
                    .offset(x: -proxy.size.width * 0.38, y: proxy.size.height * 0.60)
            }
        }
        .ignoresSafeArea()
    }
}

/// Kept for the existing screen composition; intentionally subtle in the light theme.
struct VignetteOverlay: View {
    var body: some View { Color.clear.ignoresSafeArea().allowsHitTesting(false) }
}

struct AppSurface: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppTheme.line, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.shadow.opacity(0.12), radius: 16, y: 6)
            )
    }
}

extension View {
    func appSurface(cornerRadius: CGFloat = 20) -> some View {
        modifier(AppSurface(cornerRadius: cornerRadius))
    }
}

struct ConfettiView: View {
    private let colors: [Color] = [AppTheme.coral, AppTheme.amber, AppTheme.mint, AppTheme.primary]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<70, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        endY: geo.size.height + 60,
                        delay: Double.random(in: 0...1.3),
                        duration: Double.random(in: 2.2...3.8),
                        spin: Double.random(in: 360...900),
                        size: CGFloat.random(in: 5...11)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let endY: CGFloat
    let delay: Double
    let duration: Double
    let spin: Double
    let size: CGFloat
    @State private var animate = false

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 1.6)
            .position(x: startX, y: animate ? endY : -40)
            .rotationEffect(.degrees(animate ? spin : 0))
            .opacity(animate ? 0 : 1)
            .animation(.easeIn(duration: duration).delay(delay), value: animate)
            .onAppear { animate = true }
    }
}
