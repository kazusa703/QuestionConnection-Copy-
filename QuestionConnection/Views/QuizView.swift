import SwiftUI

struct QuizView: View {
    let question: Question
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var navManager: NavigationManager
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @Environment(\.dismiss) var dismiss
    @State private var currentQuizIndex = 0
    @State private var userAnswers: [String: [String: String]] = [:]
    @State private var showResult = false
    @State private var showEssayConfirm = false
    @State private var isInCorrect = false
    @State private var isPendingSubmission = false
    private let adManager = InterstitialAdManager()
    private var hasEssay: Bool {
        question.quizItems.contains { $0.type == .essay }
    }
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                ProgressView(value: Double(currentQuizIndex + 1), total: Double(question.quizItems.count))
                    .padding()
                if currentQuizIndex < question.quizItems.count {
                    VStack(alignment: .leading, spacing: 12) {
                        let currentItem = question.quizItems[currentQuizIndex]
                        HStack(alignment: .top, spacing: 4) {
                            Text("Q\(currentQuizIndex + 1).")
                                .font(.headline)
                            if currentItem.type == .fillIn {
                                FillInQuestionTextOutlined(text: currentItem.questionText)
                            } else {
                                Text(currentItem.questionText)
                                    .font(.headline)
                            }
                        }
                        .padding()
                        if currentItem.type == .choice {
                            ChoiceQuestionView(
                                item: currentItem,
                                answer: Binding(
                                    get: { userAnswers[currentItem.id]?["choice"] ?? "" },
                                    set: { userAnswers[currentItem.id, default: [:]]["choice"] = $0 }
                                )
                            )
                        } else if currentItem.type == .fillIn {
                            FillInQuestionView(
                                item: currentItem,
                                answers: Binding(
                                    get: { userAnswers[currentItem.id] ?? [:] },
                                    set: { userAnswers[currentItem.id] = $0 }
                                )
                            )
                        } else if currentItem.type == .essay {
                            QuizEssayQuestionView(
                                item: currentItem,
                                answer: Binding(
                                    get: { userAnswers[currentItem.id]?["essay"] ?? "" },
                                    set: { userAnswers[currentItem.id, default: [:]]["essay"] = $0 }
                                )
                            )
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                }
                Button(action: handleAnswerTap) {
                    Text("回答する")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(isAnswerEmpty)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.setAuthViewModel(authViewModel)
            if !subscriptionManager.isPremium {
                adManager.loadAd()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn && isPendingSubmission {
                isPendingSubmission = false
                if currentQuizIndex < question.quizItems.count {
                    handleAnswerTap()
                } else {
                    submitAllAnswers()
                }
            }
        }
        .sheet(isPresented: $showEssayConfirm) {
            EssayConfirmView(
                isPresented: $showEssayConfirm,
                onNextTap: proceedToNextQuestion,
                onSubmitAllTap: submitAllAnswers
            )
        }
        .sheet(isPresented: $showResult) {
            if isInCorrect {
                QuizIncorrectView(
                    currentItem: question.quizItems[currentQuizIndex],
                    userAnswer: userAnswers[question.quizItems[currentQuizIndex].id] ?? [:],
                    onClose: {
                        showResult = false
                        navManager.popToRoot(tab: 0)
                        navManager.tabSelection = 0
                    }
                )
                .environmentObject(navManager)
            } else {
                QuizCompleteView(
                    question: question,
                    hasEssay: hasEssay,
                    onClose: {
                        showResult = false
                        navManager.popToRoot(tab: 0)
                        navManager.tabSelection = 0
                    },
                    onDMTap: {
                        showResult = false
                        navManager.popToRoot(tab: 2)
                        navManager.tabSelection = 2
                    }
                )
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(navManager)
            }
        }
    }
    private func handleAnswerTap() {
        let currentItem = question.quizItems[currentQuizIndex]
        let userAnswer = userAnswers[currentItem.id] ?? [:]
        if currentItem.type == .essay {
            if currentQuizIndex + 1 < question.quizItems.count {
                proceedToNextQuestion()
            } else {
                if !authViewModel.isSignedIn {
                    isPendingSubmission = true
                    showAuthenticationSheet.wrappedValue = true
                    return
                }
                submitAllAnswers()
            }
            return
        }
        let isCorrect = checkAnswer(item: currentItem, userAnswer: userAnswer)
        if isCorrect {
            if currentQuizIndex + 1 < question.quizItems.count {
                proceedToNextQuestion()
            } else {
                if !authViewModel.isSignedIn {
                    isPendingSubmission = true
                    showAuthenticationSheet.wrappedValue = true
                    return
                }
                submitAllAnswers()
            }
        } else {
            isInCorrect = true
            showResult = true
        }
    }
    private func proceedToNextQuestion() {
        if currentQuizIndex + 1 < question.quizItems.count {
            currentQuizIndex += 1
        } else {
            if !authViewModel.isSignedIn {
                isPendingSubmission = true
                showAuthenticationSheet.wrappedValue = true
                return
            }
            submitAllAnswers()
        }
    }
    private func submitAllAnswers() {
        if !authViewModel.isSignedIn {
            isPendingSubmission = true
            showAuthenticationSheet.wrappedValue = true
            return
        }
        Task {
            let success = await viewModel.submitAllAnswers(
                questionId: question.questionId,
                answers: userAnswers
            )
            await MainActor.run {
                if success {
                    isInCorrect = false
                    if subscriptionManager.isPremium {
                        showResult = true
                    } else {
                        adManager.showAd {
                            showResult = true
                        }
                    }
                }
            }
        }
    }
    private func checkAnswer(item: QuizItem, userAnswer: [String: String]) -> Bool {
        switch item.type {
        case .choice:
            let selectedId = userAnswer["choice"] ?? ""
            return selectedId == item.correctAnswerId
        case .fillIn:
            let correctAnswers = item.fillInAnswers
            if correctAnswers.isEmpty { return false }
            for (key, correctValue) in correctAnswers {
                let userValue = userAnswer[key] ?? ""
                if userValue.trimmingCharacters(in: .whitespacesAndNewlines) != correctValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return false
                }
            }
            return true
        case .essay:
            return true
        }
    }
    private var isAnswerEmpty: Bool {
        let currentItem = question.quizItems[currentQuizIndex]
        let answer = userAnswers[currentItem.id] ?? [:]
        switch currentItem.type {
        case .choice:
            let choiceValue = answer["choice"] ?? ""
            return choiceValue.isEmpty
        case .fillIn:
            let fillInAnswers = currentItem.fillInAnswers
            if fillInAnswers.isEmpty { return true }
            for key in fillInAnswers.keys {
                if (answer[key] ?? "").isEmpty {
                    return true
                }
            }
            return false
        case .essay:
            let essayValue = answer["essay"] ?? ""
            return essayValue.isEmpty
        }
    }
}

// MARK: - Subviews

struct ChoiceQuestionView: View {
    let item: QuizItem
    @Binding var answer: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !item.choices.isEmpty {
                ForEach(item.choices, id: \.id) { choice in
                    Button(action: { answer = choice.id }) {
                        HStack(spacing: 12) {
                            Image(systemName: answer == choice.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(answer == choice.id ? .blue : .gray)
                            Text(choice.text)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(12)
                        .background(answer == choice.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

struct FillInQuestionView: View {
    let item: QuizItem
    @Binding var answers: [String: String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !item.fillInAnswers.isEmpty {
                ForEach(Array(item.fillInAnswers.keys.sorted { sortKeys($0, $1) }), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            FillInAnswerBox(number: extractNumber(from: key))
                            Text("の回答:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        TextField("回答を入力", text: Binding(
                            get: { answers[key] ?? "" },
                            set: { answers[key] = $0 }
                        ))
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
    }
    private func extractNumber(from key: String) -> Int {
        let cleaned = key.replacingOccurrences(of: "穴", with: "")
        return Int(cleaned) ?? 0
    }
    private func sortKeys(_ key1: String, _ key2: String) -> Bool {
        let num1 = extractNumber(from: key1)
        let num2 = extractNumber(from: key2)
        return num1 < num2
    }
}

struct QuizEssayQuestionView: View {
    let item: QuizItem
    @Binding var answer: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("あなたの回答:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextEditor(text: $answer)
                .frame(height: 200)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            Text("※ 入力した内容は出題者に送られます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
