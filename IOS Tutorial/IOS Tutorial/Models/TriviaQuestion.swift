import Foundation

// MARK: - API Models

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

// MARK: - App Model

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let answers: [String]
}
