import SwiftUI

struct QuestionDetailView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    let question: Question
    @State private var hasAnswered: Bool? = nil
    @State private var shouldNavigateToQuiz = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            // --- ★★★ ここからが修正部分です ★★★ ---
            // 横スクロールできるようにScrollViewを追加
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // "目的" を表示 (purposeが存在する場合のみ)
                    if let purpose = question.purpose, !purpose.isEmpty {
                        Text(purpose)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(8)
                            .background(Color.green.opacity(0.15)) // タグと色分け
                            .clipShape(Capsule()) // 角を丸くする
                    }
                    
                    // "タグ" を表示
                    ForEach(question.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule()) // 角を丸くする
                    }
                }
            }
            // --- ★★★ ここまでが修正部分です ★★★ ---

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("作成者からの備考・説明").font(.headline)
                    Text(question.remarks.isEmpty ? "（備考はありません）" : question.remarks)
                        .foregroundColor(question.remarks.isEmpty ? .secondary : .primary)
                }
            }

            Spacer()

            Button(action: attemptToStartQuiz) {
                HStack {
                    Spacer()
                    if !authViewModel.isSignedIn && hasAnswered == nil {
                         Text("問題へ")
                    } else if hasAnswered == nil || quizViewModel.isLoading {
                        ProgressView()
                    } else if hasAnswered == true {
                        Text("解答済み")
                    } else {
                        Text("問題へ")
                    }
                    Spacer()
                }
                .font(.headline).padding().background(buttonBackgroundColor).foregroundColor(.white).cornerRadius(10)
            }
            .disabled(authViewModel.isSignedIn && (hasAnswered != false || quizViewModel.isLoading))

        }
        .padding()
        .navigationTitle("質問詳細")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: checkAnswerStatus)
        .onChange(of: authViewModel.idToken) { _, newToken in
            if newToken != nil && hasAnswered == nil {
                print("QuestionDetailView: idToken became available, re-checking answer status.")
                checkAnswerStatus()
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToQuiz) {
            QuizView(question: question)
        }
    }

    private func checkAnswerStatus() {
         guard let idToken = authViewModel.idToken else {
             print("QuestionDetailView: No idToken found (Guest user), setting hasAnswered to false.")
             hasAnswered = false
             return
         }
         print("QuestionDetailView: checkAnswerStatus started WITH idToken.")
         hasAnswered = nil
         Task {
             print("QuestionDetailView: Calling quizViewModel.checkIfAlreadyAnswered...")
             let result = await quizViewModel.checkIfAlreadyAnswered(questionId: question.questionId, idToken: idToken)
             print("QuestionDetailView: Received result from viewModel: \(result)")
             hasAnswered = result
             print("QuestionDetailView: checkAnswerStatus finished")
         }
     }

    private func attemptToStartQuiz() {
        guard authViewModel.isSignedIn, let idToken = authViewModel.idToken else {
            print("QuestionDetailView: Guest user attempting quiz.")
            shouldNavigateToQuiz = true
            return
        }
        print("QuestionDetailView: attemptToStartQuiz started (Logged in)")
        Task {
            let answered = await quizViewModel.checkIfAlreadyAnswered(questionId: question.questionId, idToken: idToken)
            if !answered {
                print("QuestionDetailView: Not answered, navigating to quiz.")
                shouldNavigateToQuiz = true
            } else {
                print("QuestionDetailView: Already answered, updating state (shouldn't happen if button disabled).")
                hasAnswered = true
            }
        }
    }

    private var buttonBackgroundColor: Color {
         if authViewModel.isSignedIn && hasAnswered == true {
             return .gray
         } else {
             return .accentColor
         }
     }
}

