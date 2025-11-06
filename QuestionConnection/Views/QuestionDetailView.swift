import SwiftUI
import UIKit

struct QuestionDetailView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    let question: Question
    @State private var hasAnswered: Bool? = nil
    @State private var shouldNavigateToQuiz = false
    @State private var showCopiedToast = false

    // プロフィール側のブックマーク状態（必要に応じて利用）
    private var isBookmarked: Bool {
        profileViewModel.isBookmarked(questionId: question.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // タイトル
            Text(question.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            // 目的・タグ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if let purpose = question.purpose, !purpose.isEmpty {
                        Text(purpose)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(8)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    ForEach(question.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            // 問題番号（シェアコード）
            if let code = question.shareCode, !code.isEmpty {
                HStack(spacing: 8) {
                    Text("問題番号: \(code)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation { showCopiedToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { showCopiedToast = false }
                        }
                    } label: {
                        Label("コピー", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                }
            }

            // 備考
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("作成者からの備考・説明").font(.headline)
                    Text(question.remarks.isEmpty ? "（備考はありません）" : question.remarks)
                        .foregroundColor(question.remarks.isEmpty ? .secondary : .primary)
                }
            }

            Spacer()

            // クイズ開始ボタン（既存ロジックを踏襲）
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
                .font(.headline)
                .padding()
                .background(buttonBackgroundColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(authViewModel.isSignedIn && (hasAnswered != false || quizViewModel.isLoading))

        } // End VStack
        .padding()
        .navigationTitle("質問詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 必要に応じて右上ボタン等をここに
        }
        .onAppear {
            if authViewModel.isSignedIn {
                checkAnswerStatus()
            } else {
                hasAnswered = false
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                checkAnswerStatus()
            } else {
                hasAnswered = false
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToQuiz) {
            QuizView(question: question)
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text("コピーしました")
                    .font(.caption2)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.top, 8)
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

    private func checkAnswerStatus() {
        guard authViewModel.isSignedIn else {
            hasAnswered = false
            return
        }
        hasAnswered = nil
        Task {
            let result = await quizViewModel.checkIfAlreadyAnswered(questionId: question.questionId)
            hasAnswered = result
        }
    }

    private func attemptToStartQuiz() {
        guard authViewModel.isSignedIn else {
            shouldNavigateToQuiz = true
            return
        }
        Task {
            let answered = await quizViewModel.checkIfAlreadyAnswered(questionId: question.questionId)
            if !answered {
                shouldNavigateToQuiz = true
            } else {
                hasAnswered = true
            }
        }
    }
}
