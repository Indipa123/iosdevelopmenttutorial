import SwiftUI

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case tapFrenzy
    case lightItUp
    case quizRush

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tapFrenzy: return "Tap Frenzy"
        case .lightItUp: return "Light It Up"
        case .quizRush: return "Quiz Rush"
        }
    }

    var icon: String {
        switch self {
        case .tapFrenzy: return "bolt.fill"
        case .lightItUp: return "square.grid.3x3.fill"
        case .quizRush: return "questionmark.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .tapFrenzy: return AppTheme.mint
        case .lightItUp: return AppTheme.primary
        case .quizRush: return AppTheme.coral
        }
    }

    var highScoreKey: String {
        switch self {
        case .tapFrenzy: return "highScore"
        case .lightItUp: return "lightItUpHighScore"
        case .quizRush: return "quizRushHighScore"
        }
    }
}
