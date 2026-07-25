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
            GameBackdrop(accent: AppTheme.coral)

            GeometryReader { proxy in
                let contentWidth = max(0, min(proxy.size.width - outerHorizontalPadding * 2, contentMaxWidth))

                content
                    .frame(width: contentWidth)
                    .clipped()
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }

            AppTheme.amber
                .opacity(correctFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)

            VignetteOverlay()
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
                setupHero

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
                        .foregroundColor(AppTheme.ink)
                        .tracking(1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [AppTheme.amber, AppTheme.coral], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.amber.opacity(0.55), radius: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 18)
        }
    }

    private var setupHero: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [AppTheme.amber, AppTheme.coral], startPoint: .topLeading, endPoint: .bottomTrailing))

                Image(systemName: "questionmark.text.page.fill")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(width: 78, height: 88)
            .shadow(color: AppTheme.coral.opacity(0.28), radius: 14, y: 7)

            VStack(alignment: .leading, spacing: 6) {
                Text("QUIZ RUSH")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1)

                Text("Build a ten-question challenge that is all yours.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                Label("10 QUESTIONS", systemImage: "bolt.fill")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.coral)
                    .tracking(1.2)
            }
        }
        .padding(16)
        .appSurface(cornerRadius: 26)
    }

    private var loadingView: some View {
        VStack(spacing: 22) {
            ProgressView()
                .tint(AppTheme.amber)
                .scaleEffect(1.35)

            Text("BUILDING YOUR QUIZ")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [AppTheme.ink, AppTheme.amber], startPoint: .top, endPoint: .bottom))
                .tracking(2)

            Text("Finding 10 \(viewModel.setupSummary.lowercased()) questions for your next round.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.7))
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
                .foregroundColor(AppTheme.amber)
                .shadow(color: AppTheme.amber.opacity(0.7), radius: 14)

            Text("QUIZ FAILED")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.ink)
                .tracking(2)

            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.ink.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("RETRY", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.5)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [AppTheme.amber, AppTheme.coral], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.amber.opacity(0.55), radius: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(panelBackground(cornerRadius: 24))
    }

    private var questionView: some View {
        VStack(spacing: 14) {
            quizHeader

            if let question = viewModel.currentQuestion {
                VStack(spacing: 18) {
                    HStack {
                        Label(viewModel.selectedCategory.displayName.uppercased(), systemImage: viewModel.selectedCategory.icon)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.coral)
                            .tracking(1.1)
                        Spacer()
                        Text("CHOOSE ONE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.secondaryInk)
                            .tracking(1.1)
                    }

                    Text(question.question)
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.75)

                    VStack(spacing: 10) {
                        ForEach(Array(question.answers.enumerated()), id: \.element) { index, answer in
                            answerButton(answer, index: index, question: question)
                        }
                    }
                }
                .padding(20)
                .background(panelBackground(cornerRadius: 24))
                .offset(x: wrongShake)
            }
        }
    }

    private var quizHeader: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("QUIZ RUSH")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.ink)
                        .tracking(1)

                    Text(viewModel.setupSummary.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.coral)
                        .tracking(1.2)
                }

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(AppTheme.amber)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.amber.opacity(0.12), in: Circle())
            }

            HStack(spacing: 10) {
                ScoreBadge(title: "QUESTION", value: viewModel.progressText, color: AppTheme.amber)
                ScoreBadge(title: "SCORE", value: "\(viewModel.score)", color: AppTheme.amber)
                ScoreBadge(title: "STREAK", value: "\(viewModel.streak)", color: AppTheme.mint)
            }

            GeometryReader { proxy in
                let progress = questionsProgress
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.line)
                    Capsule()
                        .fill(LinearGradient(colors: [AppTheme.amber, AppTheme.coral], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 5)
        }
    }

    private var questionsProgress: CGFloat {
        guard !viewModel.questions.isEmpty else { return 0 }
        return CGFloat(viewModel.currentIndex + 1) / CGFloat(viewModel.questions.count)
    }

    private func answerButton(_ answer: String, index: Int, question: QuizQuestion) -> some View {
        let isSelected = viewModel.selectedAnswer == answer
        let isCorrect = answer == question.correctAnswer
        let showCorrect = viewModel.selectedAnswer != nil && isCorrect
        let showWrong = isSelected && !isCorrect

        return Button {
            viewModel.submitAnswer(answer)
        } label: {
            HStack(spacing: 10) {
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(showCorrect || showWrong ? .white : AppTheme.coral)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(showCorrect ? AppTheme.mint : showWrong ? AppTheme.coral : AppTheme.coral.opacity(0.12))
                    )

                Text(answer)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .foregroundColor(showCorrect || showWrong ? .white : AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answerBackground(showCorrect: showCorrect, showWrong: showWrong))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(showCorrect ? AppTheme.mint.opacity(0.8) : showWrong ? AppTheme.coral.opacity(0.8) : AppTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedAnswer != nil)
        .accessibilityLabel("Answer: \(answer)")
        .accessibilityValue(showCorrect ? "Correct" : showWrong ? "Incorrect" : "")
        .accessibilityHint(viewModel.selectedAnswer == nil ? "Double tap to submit this answer." : "Answer submitted.")
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 54, weight: .heavy))
                .foregroundColor(AppTheme.amber)
                .shadow(color: AppTheme.amber.opacity(0.75), radius: 16)

            Text("QUIZ COMPLETE")
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.ink)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(viewModel.score)")
                .font(.system(size: 76, weight: .black, design: .rounded))
                .foregroundColor(AppTheme.amber)
                .shadow(color: AppTheme.amber.opacity(0.75), radius: 18)

            HStack(spacing: 10) {
                ScoreBadge(title: "BEST", value: "\(viewModel.highScore)", color: AppTheme.amber)
                ScoreBadge(title: "FINAL STREAK", value: "\(viewModel.streak)", color: AppTheme.mint)
            }

            Button {
                Task { await viewModel.restart() }
            } label: {
                Label("PLAY AGAIN", systemImage: "arrow.clockwise")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.5)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [AppTheme.amber, AppTheme.coral], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.amber.opacity(0.55), radius: 14)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.returnToSetup()
            } label: {
                Label("CHANGE SETUP", systemImage: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.4)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.secondaryInk.opacity(0.12))
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
            return AnyShapeStyle(LinearGradient(colors: [AppTheme.mint, AppTheme.mint.opacity(0.82)], startPoint: .leading, endPoint: .trailing))
        }
        if showWrong {
            return AnyShapeStyle(LinearGradient(colors: [.red, AppTheme.coral], startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(AppTheme.secondaryInk.opacity(0.08))
    }

    private var setupColumns: [GridItem] {
        let count = isRegularWidth ? 3 : 2
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: 10), count: count)
    }

    private func setupSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(AppTheme.ink.opacity(0.58))
            .tracking(2.5)
    }

    private func optionButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(isSelected ? .white : AppTheme.coral)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.coral.opacity(0.85) : AppTheme.coral.opacity(0.12))
                    )

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.ink)
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.coral.opacity(0.16) : AppTheme.secondaryInk.opacity(0.055))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.coral.opacity(0.9) : AppTheme.line, lineWidth: isSelected ? 2 : 1)
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
            .fill(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.secondaryInk.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow.opacity(0.12), radius: 18, y: 7)
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
                        .fill(index == 1 ? AppTheme.amber.opacity(0.9) : AppTheme.secondaryInk.opacity(0.12))
                        .frame(width: width - CGFloat(index % 2) * 28, height: rowHeight)
                        .overlay(alignment: .leading) {
                            Circle()
                                .fill(index == 1 ? AppTheme.secondaryInk.opacity(0.9) : AppTheme.secondaryInk.opacity(0.22))
                                .frame(width: rowHeight * 0.45, height: rowHeight * 0.45)
                                .padding(.leading, rowHeight * 0.35)
                        }
                        .shadow(color: index == 1 ? AppTheme.amber.opacity(0.65) : .clear, radius: 12)
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
    .preferredColorScheme(.light)
}
