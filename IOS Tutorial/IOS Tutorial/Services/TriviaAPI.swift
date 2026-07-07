import Foundation

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

// MARK: - HTML Decoding

fileprivate extension String {
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
