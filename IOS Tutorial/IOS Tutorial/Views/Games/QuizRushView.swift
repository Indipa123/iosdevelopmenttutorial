import SwiftUI

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
        .onChange(of: viewModel.feedbackToken) { _, _ in
            animateFeedback()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            setupView
        case .loading:
            loadingView
        case .failed(let message):
            errorView(message)
        case .loaded:
            questionView
        case .finished:
            resultView
        }
    }

    private var setupView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("QUIZ RUSH")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.white, .orange, .pink], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .orange.opacity(0.65), radius: 14)
                        .tracking(2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Pick your question type and challenge level.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    setupSectionTitle("QUESTION TYPE")

                    LazyVGrid(columns: setupColumns, spacing: 10) {
                        ForEach(QuizCategory.allCases) { category in
                            optionButton(
                                title: category.displayName,
                                icon: category.icon,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                }
                .padding(18)
                .background(panelBackground(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    setupSectionTitle("DIFFICULTY")

                    LazyVGrid(columns: setupColumns, spacing: 10) {
                        ForEach(QuizDifficulty.allCases) { difficulty in
                            optionButton(
                                title: difficulty.displayName,
                                icon: difficultyIcon(for: difficulty),
                                isSelected: viewModel.selectedDifficulty == difficulty
                            ) {
                                viewModel.selectedDifficulty = difficulty
                            }
                        }
                    }
                }
                .padding(18)
                .background(panelBackground(cornerRadius: 24))

                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("START \(viewModel.setupSummary.uppercased())", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .orange.opacity(0.55), radius: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 18)
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

            Text("Fetching 10 \(viewModel.setupSummary.lowercased()) questions from Open Trivia DB.")
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
                ScoreBadge(title: "QUESTION", value: viewModel.progressText, color: .orange)
                ScoreBadge(title: "SCORE", value: "\(viewModel.score)", color: .yellow)
                ScoreBadge(title: "STREAK", value: "\(viewModel.streak)", color: .green)
            }

            Text(viewModel.setupSummary.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.58))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
                ScoreBadge(title: "BEST", value: "\(viewModel.highScore)", color: .orange)
                ScoreBadge(title: "FINAL STREAK", value: "\(viewModel.streak)", color: .green)
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

            Button {
                viewModel.returnToSetup()
            } label: {
                Label("CHANGE SETUP", systemImage: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.4)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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

    private var setupColumns: [GridItem] {
        let count = isRegularWidth ? 3 : 2
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: 10), count: count)
    }

    private func setupSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.58))
            .tracking(2.5)
    }

    private func optionButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(isSelected ? .white : .orange)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.22) : Color.orange.opacity(0.16))
                    )

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.orange.opacity(0.32) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange.opacity(0.95) : Color.white.opacity(0.14), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func difficultyIcon(for difficulty: QuizDifficulty) -> String {
        switch difficulty {
        case .any: return "shuffle"
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        }
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

#Preview("Quiz Rush") {
    NavigationStack {
        QuizRushView()
    }
    .preferredColorScheme(.dark)
}
