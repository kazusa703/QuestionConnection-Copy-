import SwiftUI

// MARK: - EssayConfirmView (統合)

private struct EssayConfirmView: View {
    @Binding var isPresented: Bool
    let onNextTap: () -> Void
    let onSubmitAllTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 50)).foregroundColor(.orange)
                Text("記述式問題は出題者が採点するため")
                    .font(.headline).multilineTextAlignment(.center)
                Text("正解と仮定して次に進みます。")
                    .font(.headline).multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { isPresented = false; onNextTap() }) {
                    Text("次に進む")
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(8)
                }
                Button(action: { isPresented = false; onSubmitAllTap() }) {
                    Text("ここまでで完了する")
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Color.gray.opacity(0.3)).foregroundColor(.primary).cornerRadius(8)
                }
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.4)])
    }
}

// MARK: - QuizView

struct QuizView: View {
    let question: Question
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dmViewModel: DMViewModel
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
    private var hasEssay: Bool { question.quizItems.contains { $0.type == .essay } }
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                ProgressView(value: Double(currentQuizIndex + 1), total: Double(question.quizItems.count)).padding()
                
                if currentQuizIndex < question.quizItems.count {
                    questionContent
                }
                
                Button(action: handleAnswerTap) {
                    Text("回答する")
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(8)
                }
                .padding()
                .disabled(isAnswerEmpty)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
        .gesture(DragGesture().onChanged { if $0.translation.height > 50 { hideKeyboard() } })
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.setAuthViewModel(authViewModel)
            if !subscriptionManager.isPremium { adManager.loadAd() }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn && isPendingSubmission {
                isPendingSubmission = false
                if currentQuizIndex < question.quizItems.count { handleAnswerTap() }
                else { submitAllAnswers() }
            }
        }
        .sheet(isPresented: $showEssayConfirm) {
            EssayConfirmView(isPresented: $showEssayConfirm, onNextTap: proceedToNextQuestion, onSubmitAllTap: submitAllAnswers)
        }
        .sheet(isPresented: $showResult) {
            resultSheet
        }
        .onReceive(NotificationCenter.default.publisher(for: .forcePopToBoard)) { _ in
            showResult = false
        }
    }
    
    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let currentItem = question.quizItems[currentQuizIndex]
            HStack(alignment: .top, spacing: 4) {
                Text("Q\(currentQuizIndex + 1).").font(.headline)
                if currentItem.type == .fillIn {
                    FillInQuestionTextOutlined(text: currentItem.questionText)
                } else {
                    Text(currentItem.questionText).font(.headline)
                }
            }
            .padding()
            
            if currentItem.type == .choice {
                ChoiceQuestionView(item: currentItem, answer: Binding(
                    get: { userAnswers[currentItem.id]?["choice"] ?? "" },
                    set: { userAnswers[currentItem.id, default: [:]]["choice"] = $0 }
                ))
            } else if currentItem.type == .fillIn {
                FillInQuestionView(item: currentItem, answers: Binding(
                    get: { userAnswers[currentItem.id] ?? [:] },
                    set: { userAnswers[currentItem.id] = $0 }
                ))
            } else if currentItem.type == .essay {
                QuizEssayQuestionView(item: currentItem, answer: Binding(
                    get: { userAnswers[currentItem.id]?["essay"] ?? "" },
                    set: { userAnswers[currentItem.id, default: [:]]["essay"] = $0 }
                ))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    @ViewBuilder
    private var resultSheet: some View {
        if isInCorrect {
            QuizIncorrectView(
                currentItem: question.quizItems[currentQuizIndex],
                userAnswer: userAnswers[question.quizItems[currentQuizIndex].id] ?? [:],
                questionId: question.questionId,
                onClose: { showResult = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { navManager.popToRoot(tab: 0); navManager.tabSelection = 0 } }
            )
            .environmentObject(navManager)
        } else {
            QuizCompleteView(
                question: question,
                hasEssay: hasEssay,
                onClose: { showResult = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { navManager.popToRoot(tab: 0); navManager.tabSelection = 0 } },
                onDMTap: { showResult = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { navManager.popToRoot(tab: 2); navManager.tabSelection = 2 } }
            )
            .environmentObject(authViewModel)
            .environmentObject(profileViewModel)
            .environmentObject(dmViewModel)
            .environmentObject(navManager)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func handleAnswerTap() {
        hideKeyboard()
        let currentItem = question.quizItems[currentQuizIndex]
        let userAnswer = userAnswers[currentItem.id] ?? [:]
        
        if currentItem.type == .essay {
            if currentQuizIndex + 1 < question.quizItems.count { proceedToNextQuestion() }
            else {
                if !authViewModel.isSignedIn { isPendingSubmission = true; showAuthenticationSheet.wrappedValue = true; return }
                submitAllAnswers()
            }
            return
        }
        
        let isCorrect = checkAnswer(item: currentItem, userAnswer: userAnswer)
        if isCorrect {
            if currentQuizIndex + 1 < question.quizItems.count { proceedToNextQuestion() }
            else {
                if !authViewModel.isSignedIn { isPendingSubmission = true; showAuthenticationSheet.wrappedValue = true; return }
                submitAllAnswers()
            }
        } else {
            if !authViewModel.isSignedIn { isPendingSubmission = true; showAuthenticationSheet.wrappedValue = true; return }
            isInCorrect = true
            profileViewModel.markQuestionAsAnswered(questionId: question.questionId)
            Task {
                let success = await viewModel.submitAllAnswers(questionId: question.questionId, answers: userAnswers)
                await MainActor.run {
                    if subscriptionManager.isPremium { showResult = true }
                    else { adManager.showAd { showResult = true } }
                }
            }
        }
    }
    
    private func proceedToNextQuestion() {
        if currentQuizIndex + 1 < question.quizItems.count { currentQuizIndex += 1 }
        else {
            if !authViewModel.isSignedIn { isPendingSubmission = true; showAuthenticationSheet.wrappedValue = true; return }
            submitAllAnswers()
        }
    }
    
    private func submitAllAnswers() {
        if !authViewModel.isSignedIn { isPendingSubmission = true; showAuthenticationSheet.wrappedValue = true; return }
        Task {
            let success = await viewModel.submitAllAnswers(questionId: question.questionId, answers: userAnswers)
            await MainActor.run {
                if success {
                    profileViewModel.markQuestionAsAnswered(questionId: question.questionId)
                    isInCorrect = false
                    if subscriptionManager.isPremium { showResult = true }
                    else { adManager.showAd { showResult = true } }
                }
            }
        }
    }
    
    private func checkAnswer(item: QuizItem, userAnswer: [String: String]) -> Bool {
        switch item.type {
        case .choice: return (userAnswer["choice"] ?? "") == item.correctAnswerId
        case .fillIn:
            if item.fillInAnswers.isEmpty { return false }
            for (key, correctValue) in item.fillInAnswers {
                if (userAnswer[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines) != correctValue.trimmingCharacters(in: .whitespacesAndNewlines) { return false }
            }
            return true
        case .essay: return true
        }
    }
    
    private var isAnswerEmpty: Bool {
        let currentItem = question.quizItems[currentQuizIndex]
        let answer = userAnswers[currentItem.id] ?? [:]
        switch currentItem.type {
        case .choice: return (answer["choice"] ?? "").isEmpty
        case .fillIn:
            if currentItem.fillInAnswers.isEmpty { return true }
            for key in currentItem.fillInAnswers.keys { if (answer[key] ?? "").isEmpty { return true } }
            return false
        case .essay: return (answer["essay"] ?? "").isEmpty
        }
    }
}

// MARK: - Subviews

struct ChoiceQuestionView: View {
    let item: QuizItem
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(item.choices, id: \.id) { choice in
                Button(action: { answer = choice.id }) {
                    HStack(spacing: 12) {
                        Image(systemName: answer == choice.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(answer == choice.id ? .blue : .gray)
                        Text(choice.text).foregroundColor(.primary).multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(12)
                    .background(answer == choice.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(8)
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
            ForEach(Array(item.fillInAnswers.keys.sorted { extractNumber(from: $0) < extractNumber(from: $1) }), id: \.self) { key in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        FillInNumberBox(number: extractNumber(from: key))
                        Text("の回答:").font(.subheadline).foregroundColor(.secondary)
                    }
                    TextField("回答を入力", text: Binding(get: { answers[key] ?? "" }, set: { answers[key] = $0 }))
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding()
    }
    
    private func extractNumber(from key: String) -> Int {
        Int(key.replacingOccurrences(of: "穴", with: "")) ?? 0
    }
}

struct QuizEssayQuestionView: View {
    let item: QuizItem
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("あなたの回答:").font(.subheadline).foregroundColor(.secondary)
            TextEditor(text: $answer)
                .frame(height: 200).padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            Text("※ 入力した内容は出題者に送られます").font(.caption).foregroundColor(.secondary)
        }
        .padding()
    }
}
