import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    // ★★★ 追加: ログインシート表示用の環境変数を取得 ★★★
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    let question: Question

    @State private var currentQuestionIndex = 0
    @State private var selectedChoiceId: String?
    @State private var isAnswered = false
    @State private var score = 0

    private var isQuizFinished: Bool {
        currentQuestionIndex >= (question.quizItems).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isQuizFinished {
                // --- クイズ終了画面 ---
                VStack(spacing: 20) {
                    Text("クイズ終了！").font(.largeTitle)
                    Text("スコア: \(score) / \((question.quizItems).count)").font(.title2)

                    // 全問正解した場合のみボタンを表示
                    if score == (question.quizItems).count {
                        // ★★★ 修正箇所 ★★★
                        // ログイン状態に応じてボタンのアクションと見た目を変更
                        if authViewModel.isSignedIn {
                            // ログイン済み: DM作成画面へ遷移
                            NavigationLink(destination: InitialDMView(recipientId: question.authorId, questionTitle: question.title)) {
                                Text("作成者にDMを送る")
                                    .font(.headline).padding()
                                    .background(Color.green)
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                        } else {
                            // 未ログイン: ログインシートを表示するボタン
                            Button {
                                showAuthenticationSheet.wrappedValue = true
                            } label: {
                                Text("ログインして質問作成者にdmを送る")
                                    .font(.headline).padding()
                                    .background(Color.orange) // 色を変えるなど
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                        }
                        // ★★★ ここまで ★★★
                    }
                } // End VStack (Quiz Finished)
            } else {
                // --- クイズ進行中の画面 ---
                let currentQuizItem = (question.quizItems)[currentQuestionIndex]

                Text("問題 \(currentQuestionIndex + 1)").font(.headline)
                Text(currentQuizItem.questionText).font(.title).fontWeight(.bold)
                Spacer()

                ForEach(currentQuizItem.choices) { choice in
                    Button(action: {
                        if !isAnswered {
                            selectedChoiceId = choice.id
                            isAnswered = true
                            let isCorrect = (choice.id == currentQuizItem.correctAnswerId)
                            if isCorrect {
                                score += 1
                            }
                            // ★★★ 修正箇所: ログインしている場合のみ回答を記録 ★★★
                            if authViewModel.isSignedIn {
                                logAnswer(choiceId: choice.id, isCorrect: isCorrect)
                            } else {
                                print("ゲストユーザーのため回答は記録されません。")
                            }
                            // ★★★ ここまで ★★★
                        }
                    }) {
                        Text(choice.text).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(getButtonColor(choice: choice))
                } // End ForEach (Choices)

                Spacer()

                if isAnswered {
                    Button(action: {
                        currentQuestionIndex += 1
                        isAnswered = false
                        selectedChoiceId = nil
                    }) {
                        Text(currentQuestionIndex + 1 >= (question.quizItems).count ? "結果を見る" : "次の問題へ")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } // End else (Quiz In-Progress)
        } // End VStack (Main)
        .padding()
        .navigationTitle("クイズ")
        .navigationBarBackButtonHidden(true)
    } // End body

    func getButtonColor(choice: Choice) -> Color {
        guard isAnswered, let selectedChoiceId = self.selectedChoiceId else { return .accentColor }
        let currentCorrectAnswerId = (question.quizItems)[currentQuestionIndex].correctAnswerId
        if choice.id == currentCorrectAnswerId { return .green }
        if choice.id == selectedChoiceId { return .red }
        return .gray
    }

    // logAnswer関数のシグネチャは変更なし (ViewModel側でログインチェック)
    func logAnswer(choiceId: String, isCorrect: Bool) {
        // userIdとidTokenはオプショナルで渡す
        Task {
            await viewModel.logAnswer(
                questionId: question.questionId,
                userId: authViewModel.userSub, // nilの可能性あり
                selectedChoiceId: choiceId,
                isCorrect: isCorrect,
                idToken: authViewModel.idToken // nilの可能性あり
            )
        }
    }
} // End struct
