import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    let question: Question

    @State private var currentQuestionIndex = 0
    @State private var selectedChoiceId: String?
    @State private var isAnswered = false
    @State private var score = 0

    private var isQuizFinished: Bool {
        currentQuestionIndex >= question.quizItems.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isQuizFinished {
                VStack(spacing: 20) {
                    Text("クイズ終了！").font(.largeTitle)
                    Text("スコア: \(score) / \(question.quizItems.count)").font(.title2)

                    if score == question.quizItems.count {
                        if authViewModel.isSignedIn {
                            NavigationLink(
                                destination: InitialDMView(
                                    recipientId: question.authorId,
                                    questionTitle: question.title
                                )
                            ) {
                                Text("作成者にDMを送る")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        } else {
                            Button {
                                showAuthenticationSheet.wrappedValue = true
                            } label: {
                                Text("ログインして質問作成者にdmを送る")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }

                        // 作成者からのメッセージ（任意）
                        if let raw = question.dmInviteMessage,
                           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("作成者からのメッセージ")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(raw.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            } else {
                let currentQuizItem = question.quizItems[currentQuestionIndex]

                Text("問題 \(currentQuestionIndex + 1)").font(.headline)
                Text(currentQuizItem.questionText).font(.title).fontWeight(.bold)
                Spacer()

                ForEach(currentQuizItem.choices) { choice in
                    Button {
                        if !isAnswered {
                            selectedChoiceId = choice.id
                            isAnswered = true
                            let isCorrect = (choice.id == currentQuizItem.correctAnswerId)
                            if isCorrect { score += 1 }
                            if authViewModel.isSignedIn {
                                logAnswer(choiceId: choice.id, isCorrect: isCorrect)
                            } else {
                                print("ゲストユーザーのため回答は記録されません。")
                            }
                        }
                    } label: {
                        Text(choice.text).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(getButtonColor(choice: choice))
                }

                Spacer()

                if isAnswered {
                    Button {
                        let isFinishing = (currentQuestionIndex + 1 >= question.quizItems.count)
                        if isFinishing {
                            Task {
                                await viewModel.reportQuizCompletion(
                                    questionId: question.questionId,
                                    score: score,
                                    totalQuestions: question.quizItems.count
                                )
                            }
                        }
                        currentQuestionIndex += 1
                        isAnswered = false
                        selectedChoiceId = nil
                    } label: {
                        Text(currentQuestionIndex + 1 >= question.quizItems.count ? "結果を見る" : "次の問題へ")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("クイズ")
        .navigationBarBackButtonHidden(true)
        .task {
            viewModel.setAuthViewModel(authViewModel)
            // デバッグ（必要なら一時的にON）
            // print("dmInviteMessage:", question.dmInviteMessage ?? "nil")
        }
    }

    func getButtonColor(choice: Choice) -> Color {
        guard isAnswered, let selectedChoiceId = self.selectedChoiceId else { return .accentColor }
        let currentCorrectAnswerId = question.quizItems[currentQuestionIndex].correctAnswerId
        if choice.id == currentCorrectAnswerId { return .green }
        if choice.id == selectedChoiceId { return .red }
        return .gray
    }

    func logAnswer(choiceId: String, isCorrect: Bool) {
        Task {
            await viewModel.logAnswer(
                questionId: question.questionId,
                userId: authViewModel.userSub,
                selectedChoiceId: choiceId,
                isCorrect: isCorrect
            )
        }
    }
}
