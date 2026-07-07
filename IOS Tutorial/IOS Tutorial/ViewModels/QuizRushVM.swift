import Foundation
internal import Combine

@MainActor
final class QuizRushViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
        case finished
    }

    enum AnswerFeedback: Equatable {
        case correct
        case wrong
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var highScore: Int
    @Published private(set) var selectedAnswer: String?
    @Published private(set) var feedback: AnswerFeedback?
    @Published private(set) var feedbackToken = UUID()

    private let service: TriviaQuestionServicing
    private let highScoreKey = "quizRushHighScore"
    private var isAnswerLocked = false

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressText: String {
        "\(min(currentIndex + 1, questions.count)) of \(questions.count)"
    }

    convenience init() {
        self.init(service: OpenTriviaService())
    }

    init(service: TriviaQuestionServicing) {
        self.service = service
        self.highScore = UserDefaults.standard.integer(forKey: highScoreKey)
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        state = .loading
        resetRound(keepingQuestions: false)

        do {
            questions = try await service.fetchQuestions()
            state = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
            state = .failed(message)
        }
    }

    func retry() async {
        await load()
    }

    func restart() async {
        await load()
    }

    func submitAnswer(_ answer: String) {
        guard !isAnswerLocked, state == .loaded, let question = currentQuestion else { return }

        isAnswerLocked = true
        selectedAnswer = answer

        if answer == question.correctAnswer {
            streak += 1
            score += 10 + max(0, streak - 1) * 3
            feedback = .correct
        } else {
            streak = 0
            score = max(0, score - 2)
            feedback = .wrong
        }

        feedbackToken = UUID()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 550_000_000)
            advanceAfterFeedback()
        }
    }

    private func advanceAfterFeedback() {
        selectedAnswer = nil
        feedback = nil
        isAnswerLocked = false

        if currentIndex + 1 >= questions.count {
            finishRound()
        } else {
            currentIndex += 1
        }
    }

    private func finishRound() {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: highScoreKey)
        }
        // TODO (Week 4 Step 3): append a GameSession via GameSessionStore here.
        state = .finished
    }

    private func resetRound(keepingQuestions: Bool) {
        if !keepingQuestions { questions = [] }
        currentIndex = 0
        score = 0
        streak = 0
        selectedAnswer = nil
        feedback = nil
        isAnswerLocked = false
    }
}
