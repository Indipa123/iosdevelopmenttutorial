import SwiftUI
import UIKit

enum PlayerAvatar: String, CaseIterable, Identifiable {
    case aria
    case jules
    case leo
    case noor
    case mika
    case rio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aria: "Aria"
        case .jules: "Jules"
        case .leo: "Leo"
        case .noor: "Noor"
        case .mika: "Mika"
        case .rio: "Rio"
        }
    }

    var skinTone: Color {
        switch self {
        case .aria: Color(red: 0.96, green: 0.76, blue: 0.61)
        case .jules: Color(red: 0.78, green: 0.50, blue: 0.33)
        case .leo: Color(red: 0.55, green: 0.32, blue: 0.20)
        case .noor: Color(red: 0.38, green: 0.22, blue: 0.15)
        case .mika: Color(red: 0.94, green: 0.69, blue: 0.49)
        case .rio: Color(red: 0.67, green: 0.40, blue: 0.26)
        }
    }

    var hairColor: Color {
        switch self {
        case .aria: Color(red: 0.18, green: 0.13, blue: 0.19)
        case .jules: Color(red: 0.12, green: 0.14, blue: 0.18)
        case .leo: Color(red: 0.88, green: 0.35, blue: 0.14)
        case .noor: Color(red: 0.05, green: 0.06, blue: 0.08)
        case .mika: Color(red: 0.82, green: 0.57, blue: 0.12)
        case .rio: Color(red: 0.20, green: 0.12, blue: 0.13)
        }
    }

    var outfitColor: Color {
        switch self {
        case .aria: Color(red: 0.19, green: 0.63, blue: 0.65)
        case .jules: Color(red: 0.18, green: 0.38, blue: 0.82)
        case .leo: Color(red: 0.91, green: 0.34, blue: 0.27)
        case .noor: Color(red: 0.47, green: 0.30, blue: 0.77)
        case .mika: Color(red: 0.92, green: 0.46, blue: 0.62)
        case .rio: Color(red: 0.86, green: 0.54, blue: 0.10)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .aria: Color(red: 0.78, green: 0.94, blue: 0.91)
        case .jules: Color(red: 0.80, green: 0.87, blue: 1.00)
        case .leo: Color(red: 1.00, green: 0.88, blue: 0.75)
        case .noor: Color(red: 0.88, green: 0.82, blue: 1.00)
        case .mika: Color(red: 1.00, green: 0.83, blue: 0.90)
        case .rio: Color(red: 1.00, green: 0.91, blue: 0.70)
        }
    }

    var hairStyle: FaceHairStyle {
        switch self {
        case .aria: .long
        case .jules: .short
        case .leo: .curly
        case .noor: .pigtails
        case .mika: .bun
        case .rio: .wave
        }
    }
}

enum FaceHairStyle {
    case long, short, curly, pigtails, bun, wave
}

enum PlayerProfilePhoto {
    /// A profile image does not need the full camera resolution. Keeping a
    /// compact JPEG makes persistence in UserDefaults reliable and quick.
    static func optimizedData(from data: Data, maxDimension: CGFloat = 640) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let largestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / max(largestSide, 1))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.82)
    }
}

/// Small, original illustrated faces for the built-in player avatars.
struct FaceAvatarArtwork: View {
    let avatar: PlayerAvatar

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle().fill(avatar.backgroundColor)

                RoundedRectangle(cornerRadius: side * 0.23, style: .continuous)
                    .fill(avatar.outfitColor)
                    .frame(width: side * 0.76, height: side * 0.45)
                    .offset(y: side * 0.42)

                backHair(side: side)

                Circle()
                    .fill(avatar.skinTone)
                    .frame(width: side * 0.56, height: side * 0.56)
                    .offset(y: -side * 0.03)

                faceFeatures(side: side)
                frontHair(side: side)
                accessory(side: side)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func backHair(side: CGFloat) -> some View {
        switch avatar.hairStyle {
        case .long:
            Capsule()
                .fill(avatar.hairColor)
                .frame(width: side * 0.66, height: side * 0.74)
                .offset(y: side * 0.02)
        case .short, .bun, .wave:
            EmptyView()
        case .curly:
            HStack(spacing: -side * 0.10) {
                Circle().fill(avatar.hairColor)
                Circle().fill(avatar.hairColor)
                Circle().fill(avatar.hairColor)
            }
            .frame(width: side * 0.72, height: side * 0.60)
            .offset(y: -side * 0.10)
        case .pigtails:
            HStack(spacing: side * 0.36) {
                Circle().fill(avatar.hairColor)
                Circle().fill(avatar.hairColor)
            }
            .frame(width: side * 0.80, height: side * 0.36)
            .offset(y: -side * 0.03)
        }
    }

    private func faceFeatures(side: CGFloat) -> some View {
        ZStack {
            HStack(spacing: side * 0.15) {
                Circle().fill(AppTheme.ink).frame(width: side * 0.052, height: side * 0.052)
                Circle().fill(AppTheme.ink).frame(width: side * 0.052, height: side * 0.052)
            }
            .offset(y: -side * 0.07)

            Capsule()
                .fill(avatar.hairColor.opacity(0.72))
                .frame(width: side * 0.16, height: side * 0.026)
                .offset(y: side * 0.12)

            if avatar == .leo {
                HStack(spacing: side * 0.19) {
                    Circle().fill(avatar.hairColor.opacity(0.55)).frame(width: side * 0.025, height: side * 0.025)
                    Circle().fill(avatar.hairColor.opacity(0.55)).frame(width: side * 0.025, height: side * 0.025)
                }
                .offset(y: side * 0.035)
            }
        }
    }

    @ViewBuilder
    private func frontHair(side: CGFloat) -> some View {
        switch avatar.hairStyle {
        case .long:
            Capsule()
                .fill(avatar.hairColor)
                .frame(width: side * 0.57, height: side * 0.27)
                .offset(y: -side * 0.28)
        case .short:
            Ellipse()
                .fill(avatar.hairColor)
                .frame(width: side * 0.60, height: side * 0.31)
                .offset(y: -side * 0.29)
        case .curly:
            HStack(spacing: -side * 0.08) {
                ForEach(0..<4, id: \.self) { _ in
                    Circle().fill(avatar.hairColor)
                }
            }
            .frame(width: side * 0.66, height: side * 0.28)
            .offset(y: -side * 0.31)
        case .pigtails:
            RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                .fill(avatar.hairColor)
                .frame(width: side * 0.59, height: side * 0.24)
                .offset(y: -side * 0.30)
        case .bun:
            ZStack {
                Circle()
                    .fill(avatar.hairColor)
                    .frame(width: side * 0.28, height: side * 0.28)
                    .offset(y: -side * 0.49)
                Capsule()
                    .fill(avatar.hairColor)
                    .frame(width: side * 0.58, height: side * 0.24)
                    .offset(y: -side * 0.30)
            }
        case .wave:
            HStack(spacing: -side * 0.07) {
                Circle().fill(avatar.hairColor)
                Circle().fill(avatar.hairColor)
                Circle().fill(avatar.hairColor)
            }
            .frame(width: side * 0.63, height: side * 0.25)
            .offset(y: -side * 0.31)
        }
    }

    @ViewBuilder
    private func accessory(side: CGFloat) -> some View {
        if avatar == .jules {
            HStack(spacing: side * 0.06) {
                Circle().stroke(AppTheme.ink.opacity(0.80), lineWidth: max(1.2, side * 0.022))
                Circle().stroke(AppTheme.ink.opacity(0.80), lineWidth: max(1.2, side * 0.022))
            }
            .frame(width: side * 0.40, height: side * 0.17)
            .offset(y: -side * 0.07)
        }
    }
}

struct PlayerAvatarImage: View {
    let avatarRawValue: String
    let photoData: Data
    let usesCustomPhoto: Bool
    var size: CGFloat = 60

    private var avatar: PlayerAvatar {
        PlayerAvatar(rawValue: avatarRawValue) ?? .aria
    }

    var body: some View {
        Group {
            if usesCustomPhoto, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                FaceAvatarArtwork(avatar: avatar)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.surface.opacity(0.85), lineWidth: max(2, size * 0.045)))
        .overlay(Circle().stroke(avatar.outfitColor.opacity(usesCustomPhoto ? 0.35 : 0.24), lineWidth: 1))
        .accessibilityLabel(usesCustomPhoto ? "Custom player photo" : "\(avatar.title) player avatar")
    }
}

struct AvatarChoice: View {
    let avatar: PlayerAvatar
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            FaceAvatarArtwork(avatar: avatar)
                .frame(width: 44, height: 44)

            Text(avatar.title.uppercased())
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.secondaryInk)
                .tracking(0.65)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isSelected ? avatar.outfitColor.opacity(0.11) : AppTheme.secondaryInk.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(isSelected ? avatar.outfitColor.opacity(0.85) : AppTheme.line, lineWidth: isSelected ? 2 : 1)
        )
    }
}
