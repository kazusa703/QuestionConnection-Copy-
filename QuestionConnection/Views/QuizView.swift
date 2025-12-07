import SwiftUI

struct QuizView: View {
    let question: Question
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @State private var currentQuizIndex = 0
    @State private var userAnswers: [String: [String: String]] = [:]
    @State private var showResult = false
    @State private var showEssayConfirm = false
    @State private var hasEssayQuestion = false
    @State private var isInCorrect = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                ProgressView(value: Double(currentQuizIndex + 1), total: Double(question.quizItems.count))
                    .padding()
                
                if currentQuizIndex < question.quizItems.count {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Q\(currentQuizIndex + 1). \(question.quizItems[currentQuizIndex].questionText)")
                            .font(.headline)
                            .padding()
                        
                        let currentItem = question.quizItems[currentQuizIndex]
                        
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
                            EssayQuestionView(
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
                    userAnswer: userAnswers[question.quizItems[currentQuizIndex].id] ?? [:]
                )
            } else {
                QuizCompleteView(question: question, hasEssay: question.quizItems.contains { $0.type == .essay })
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
            }
        }
    }
    
    private func handleAnswerTap() {
        let currentItem = question.quizItems[currentQuizIndex]
        let userAnswer = userAnswers[currentItem.id] ?? [:]
        
        let isCorrect = checkAnswer(item: currentItem, userAnswer: userAnswer)
        
        if isCorrect {
            if currentQuizIndex + 1 < question.quizItems.count {
                let nextItem = question.quizItems[currentQuizIndex + 1]
                if nextItem.type == .essay {
                    hasEssayQuestion = true
                    showEssayConfirm = true
                    return
                }
            }
            
            proceedToNextQuestion()
        } else {
            isInCorrect = true
            showResult = true
        }
    }
    
    private func proceedToNextQuestion() {
        if currentQuizIndex + 1 < question.quizItems.count {
            currentQuizIndex += 1
        } else {
            submitAllAnswers()
        }
    }
    
    // QuizView.swift の submitAllAnswers 関数を以下に置き換え

    private func submitAllAnswers() {
        Task {
            guard let uid = authViewModel.userSub else { return }
            
            // ★★★ 修正: 記述式の有無を判定して渡す ★★★
            let hasEssay = question.quizItems.contains { $0.type == . essay }
            
            let success = await viewModel.submitAllAnswers(
                questionId: question.questionId,
                answers: userAnswers,
                hasEssay: hasEssay  // ★★★ 追加 ★★★
            )
            
            await MainActor.run {
                if success {
                    isInCorrect = false
                    showResult = true
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
                if userValue.trimmingCharacters(in: .whitespacesAndNewlines) !=
                    correctValue.trimmingCharacters(in: .whitespacesAndNewlines) {
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
                ForEach(Array(item.fillInAnswers.keys.sorted()), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("[\(key)]の回答:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("回答を入力", text: Binding(
                            get: { answers[key] ?? "" },
                            set: { answers[key] = $0 }
                        ))
                        .padding(10)
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
}
