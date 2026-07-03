import SwiftUI
import Foundation
internal import Combine

// MARK: - API Model

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

// MARK: - Network Service

protocol TriviaQuestionServicing {
    func fetchQuestions() async throws -> [QuizQuestion]
}

struct OpenTriviaService: TriviaQuestionServicing {
    private let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!

    func fetchQuestions() async throws -> [QuizQuestion] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw QuizRushError.badResponse
        }

        let decoded = try JSONDecoder().decode(TriviaAPIResponse.self, from: data)
        guard !decoded.results.isEmpty else { throw QuizRushError.emptyQuestions }

        return decoded.results.map { item in
            let correctAnswer = item.correctAnswer.htmlDecoded
            let incorrectAnswers = item.incorrectAnswers.map(\.htmlDecoded)
            let answers = ([correctAnswer] + incorrectAnswers).shuffled()

            return QuizQuestion(
                question: item.question.htmlDecoded,
                correctAnswer: correctAnswer,
                answers: answers
            )
        }
    }
}

enum QuizRushError: LocalizedError {
    case badResponse
    case emptyQuestions

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Could not reach Open Trivia DB."
        case .emptyQuestions:
            return "No questions were returned."
        }
    }
}

// MARK: - ViewModel

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

// MARK: - Quiz Rush View

struct QuizRushView: View {
    @StateObject private var viewModel = QuizRushViewModel()
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var wrongShake: CGFloat = 0
    @State private var correctFlashOpacity = 0.0

    private var isRegularWidth: Bool { hSize == .regular }
    private var contentMaxWidth: CGFloat { isRegularWidth ? 640 : 360 }
    private var outerHorizontalPadding: CGFloat { isRegularWidth ? 28 : 16 }

    var body: some View {
        ZStack {
            WallpaperBackground()

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                content
                    .frame(width: contentWidth)
                    .clipped()
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }

            Color.green
                .opacity(correctFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)

            VignetteOverlay()
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.feedbackToken) { _, _ in
            animateFeedback()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .failed(let message):
            errorView(message)
        case .loaded:
            questionView
        case .finished:
            resultView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 22) {
            ProgressView()
                .tint(.orange)
                .scaleEffect(1.35)

            Text("LOADING QUIZ")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, .orange], startPoint: .top, endPoint: .bottom))
                .tracking(2)

            Text("Fetching 10 live questions from Open Trivia DB.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(panelBackground(cornerRadius: 24))
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 46, weight: .heavy))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.7), radius: 14)

            Text("QUIZ FAILED")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("RETRY", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .orange.opacity(0.55), radius: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(panelBackground(cornerRadius: 24))
    }

    private var questionView: some View {
        VStack(spacing: 18) {
            quizHeader

            if let question = viewModel.currentQuestion {
                VStack(spacing: 16) {
                    Text(question.question)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .minimumScaleFactor(0.75)

                    VStack(spacing: 10) {
                        ForEach(question.answers, id: \.self) { answer in
                            answerButton(answer, question: question)
                        }
                    }
                }
                .padding(18)
                .background(panelBackground(cornerRadius: 24))
                .offset(x: wrongShake)
            }
        }
    }

    private var quizHeader: some View {
        VStack(spacing: 12) {
            Text("QUIZ RUSH")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, .orange, .pink], startPoint: .top, endPoint: .bottom))
                .shadow(color: .orange.opacity(0.65), radius: 14)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 10) {
                QuizStatPill(title: "QUESTION", value: viewModel.progressText, color: .orange)
                QuizStatPill(title: "SCORE", value: "\(viewModel.score)", color: .yellow)
                QuizStatPill(title: "STREAK", value: "\(viewModel.streak)", color: .green)
            }
        }
    }

    private func answerButton(_ answer: String, question: QuizQuestion) -> some View {
        let isSelected = viewModel.selectedAnswer == answer
        let isCorrect = answer == question.correctAnswer
        let showCorrect = viewModel.selectedAnswer != nil && isCorrect
        let showWrong = isSelected && !isCorrect

        return Button {
            viewModel.submitAnswer(answer)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showCorrect ? "checkmark.circle.fill" : showWrong ? "xmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .heavy))

                Text(answer)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answerBackground(showCorrect: showCorrect, showWrong: showWrong))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(showCorrect || showWrong ? 0.45 : 0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedAnswer != nil)
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 54, weight: .heavy))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.75), radius: 16)

            Text("QUIZ COMPLETE")
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(viewModel.score)")
                .font(.system(size: 76, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.75), radius: 18)

            HStack(spacing: 10) {
                QuizStatPill(title: "BEST", value: "\(viewModel.highScore)", color: .orange)
                QuizStatPill(title: "FINAL STREAK", value: "\(viewModel.streak)", color: .green)
            }

            Button {
                Task { await viewModel.restart() }
            } label: {
                Label("PLAY AGAIN", systemImage: "arrow.clockwise")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .orange.opacity(0.55), radius: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(panelBackground(cornerRadius: 28))
    }

    private func animateFeedback() {
        guard let feedback = viewModel.feedback else { return }

        switch feedback {
        case .correct:
            withAnimation(.easeOut(duration: 0.12)) {
                correctFlashOpacity = 0.28
            }
            withAnimation(.easeIn(duration: 0.28).delay(0.12)) {
                correctFlashOpacity = 0
            }
        case .wrong:
            withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
                wrongShake = 12
            }
            withAnimation(.linear(duration: 0.06).delay(0.32)) {
                wrongShake = 0
            }
        }
    }

    private func answerBackground(showCorrect: Bool, showWrong: Bool) -> some ShapeStyle {
        if showCorrect {
            return AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
        }
        if showWrong {
            return AnyShapeStyle(LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(Color.white.opacity(0.08))
    }

    private func panelBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 20, y: 8)
    }
}

struct QuizStatPill: View {
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

// MARK: - Home Preview

struct QuizRushPreview: View {
    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width * 0.74, 260)
            let rowHeight = max(14, min(24, geo.size.height * 0.16))

            VStack(spacing: rowHeight * 0.35) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: rowHeight * 0.45)
                        .fill(index == 1 ? Color.orange.opacity(0.9) : Color.white.opacity(0.12))
                        .frame(width: width - CGFloat(index % 2) * 28, height: rowHeight)
                        .overlay(alignment: .leading) {
                            Circle()
                                .fill(index == 1 ? Color.white.opacity(0.9) : Color.white.opacity(0.22))
                                .frame(width: rowHeight * 0.45, height: rowHeight * 0.45)
                                .padding(.leading, rowHeight * 0.35)
                        }
                        .shadow(color: index == 1 ? .orange.opacity(0.65) : .clear, radius: 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - HTML Decoding

private extension String {
    var htmlDecoded: String {
        self
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&eacute;", with: "e")
            .replacingOccurrences(of: "&uuml;", with: "u")
            .replacingOccurrences(of: "&rsquo;", with: "'")
            .replacingOccurrences(of: "&ldquo;", with: "\"")
            .replacingOccurrences(of: "&rdquo;", with: "\"")
            .replacingNumericHTMLEntities()
    }

    private func replacingNumericHTMLEntities() -> String {
        let pattern = #"&#(x?[0-9A-Fa-f]+);"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }

        var result = self
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed()

        for match in matches {
            guard match.numberOfRanges == 2,
                  let fullRange = Range(match.range(at: 0), in: result),
                  let valueRange = Range(match.range(at: 1), in: result) else { continue }

            let rawValue = String(result[valueRange])
            let radix = rawValue.hasPrefix("x") ? 16 : 10
            let digits = rawValue.hasPrefix("x") ? String(rawValue.dropFirst()) : rawValue

            if let scalarValue = UInt32(digits, radix: radix),
               let scalar = UnicodeScalar(scalarValue) {
                result.replaceSubrange(fullRange, with: String(Character(scalar)))
            }
        }

        return result
    }
}

#Preview("Quiz Rush") {
    NavigationStack {
        QuizRushView()
    }
    .preferredColorScheme(.dark)
}
