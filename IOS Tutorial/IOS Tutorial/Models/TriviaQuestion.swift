import Foundation

enum QuizDifficulty: String, CaseIterable, Identifiable {
    case any
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .any: return "Any"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var apiValue: String? {
        self == .any ? nil : rawValue
    }

    var baseScore: Int {
        switch self {
        case .any, .easy: return 10
        case .medium: return 15
        case .hard: return 20
        }
    }
}

enum QuizCategory: CaseIterable, Identifiable {
    case any
    case sports
    case movies
    case geography
    case history
    case science
    case computers
    case music
    case animals

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .any: return "Mixed"
        case .sports: return "Sports"
        case .movies: return "Movies"
        case .geography: return "Geography"
        case .history: return "History"
        case .science: return "Science"
        case .computers: return "Computers"
        case .music: return "Music"
        case .animals: return "Animals"
        }
    }

    var icon: String {
        switch self {
        case .any: return "sparkles"
        case .sports: return "sportscourt.fill"
        case .movies: return "film.fill"
        case .geography: return "globe.americas.fill"
        case .history: return "clock.fill"
        case .science: return "atom"
        case .computers: return "desktopcomputer"
        case .music: return "music.note"
        case .animals: return "pawprint.fill"
        }
    }

    var apiID: Int? {
        switch self {
        case .any: return nil
        case .sports: return 21
        case .movies: return 11
        case .geography: return 22
        case .history: return 23
        case .science: return 17
        case .computers: return 18
        case .music: return 12
        case .animals: return 27
        }
    }
}

struct TriviaAPIResponse: Decodable {
    let results: [TriviaQuestionDTO]
}

struct TriviaQuestionDTO: Decodable {
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let answers: [String]
}
