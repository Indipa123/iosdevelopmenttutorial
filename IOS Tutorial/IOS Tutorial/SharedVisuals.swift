import SwiftUI

struct WallpaperBackground: View {
    @State private var gradientShift = false
    @State private var orbDrift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientShift
                    ? [.black, .indigo.opacity(0.9), .blue.opacity(0.8)]
                    : [.black, .blue.opacity(0.85), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: gradientShift)

            glowOrbs
                .allowsHitTesting(false)

            NeonGrid()
                .allowsHitTesting(false)

            AmbientParticles()
                .allowsHitTesting(false)
        }
        .onAppear {
            gradientShift.toggle()
            orbDrift.toggle()
        }
    }

    private var glowOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.purple.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 280
                    )
                )
                .frame(width: 560, height: 560)
                .blur(radius: 50)
                .offset(x: orbDrift ? -120 : 140, y: -260)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.cyan.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 260
                    )
                )
                .frame(width: 480, height: 480)
                .blur(radius: 50)
                .offset(x: orbDrift ? 180 : -180, y: 340)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.pink.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 40)
                .offset(x: orbDrift ? 100 : -100, y: 0)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: orbDrift)
    }
}

struct VignetteOverlay: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.55)],
            center: .center,
            startRadius: 200,
            endRadius: 540
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct NeonGrid: View {
    @State private var scroll: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let horizonY = h * 0.62
            let gridHeight = h - horizonY
            let vanish = CGPoint(x: w / 2, y: horizonY)

            ZStack {
                Canvas { context, _ in
                    let rows = 14
                    for i in 0...rows {
                        let raw = (CGFloat(i) + scroll).truncatingRemainder(dividingBy: CGFloat(rows))
                        let t = raw / CGFloat(rows)
                        let eased = pow(t, 2)
                        let y = horizonY + gridHeight * eased
                        let alpha = 0.55 * (1 - t) + 0.05
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                        context.stroke(
                            path,
                            with: .color(.cyan.opacity(alpha)),
                            lineWidth: 1.2
                        )
                    }

                    let cols = 18
                    for i in 0...cols {
                        let x = CGFloat(i) / CGFloat(cols) * w
                        var path = Path()
                        path.move(to: vanish)
                        path.addLine(to: CGPoint(x: x, y: h))
                        context.stroke(
                            path,
                            with: .color(.cyan.opacity(0.35)),
                            lineWidth: 1
                        )
                    }
                }
                .blur(radius: 0.4)
                .shadow(color: .cyan.opacity(0.6), radius: 6)
                .opacity(0.55)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gridHeight)
                .offset(y: horizonY)
                .blendMode(.multiply)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    scroll = 14
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct AmbientParticles: View {
    private let particles: [AmbientParticle] = (0..<25).map { _ in
        AmbientParticle(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            duration: Double.random(in: 6...14),
            delay: Double.random(in: 0...4)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    AmbientDot(particle: particle, screen: geo.size)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct AmbientParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
}

struct AmbientDot: View {
    let particle: AmbientParticle
    let screen: CGSize
    @State private var drift = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.35))
            .frame(width: particle.size, height: particle.size)
            .blur(radius: 0.5)
            .position(
                x: particle.x * screen.width,
                y: drift ? -20 : particle.y * screen.height + 40
            )
            .opacity(drift ? 0 : 0.8)
            .onAppear {
                withAnimation(
                    .linear(duration: particle.duration)
                        .repeatForever(autoreverses: false)
                        .delay(particle.delay)
                ) {
                    drift = true
                }
            }
    }
}

struct ConfettiView: View {
    private let colors: [Color] = [.red, .yellow, .green, .blue, .pink, .orange, .purple, .cyan]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<90, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        endY: geo.size.height + 60,
                        delay: Double.random(in: 0...1.8),
                        duration: Double.random(in: 2.5...4.5),
                        spin: Double.random(in: 360...1080),
                        size: CGFloat.random(in: 6...14)
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
            .shadow(color: color.opacity(0.6), radius: 3)
            .animation(.easeIn(duration: duration).delay(delay), value: animate)
            .onAppear { animate = true }
    }
}
