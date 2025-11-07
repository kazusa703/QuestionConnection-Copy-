import SwiftUI
import UIKit

struct QuestionDetailView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // ★★★ 通報機能用のStateを追加 ★★★
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @State private var showingReportAlert = false // 通報確認アラート
    @State private var showingReportSuccessToast = false // 通報成功トースト
    @State private var isReporting = false // 通報処理中フラグ

    let question: Question
    @State private var hasAnswered: Bool? = nil
    @State private var shouldNavigateToQuiz = false
    @State private var showCopiedToast = false

    // プロフィール側のブックマーク状態（必要に応じて利用）
    private var isBookmarked: Bool {
        profileViewModel.isBookmarked(questionId: question.id)
    }

    // --- ★★★ エラー解決: body を2つに分割 ① ★★★ ---
    // (VStackの中身をこちらに移動)
    private var contentBody: some View {
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
    }
    
    // --- ★★★ エラー解決: body を2つに分割 ② ★★★ ---
    // (モディファイアはこちらに残す)
    var body: some View {
        contentBody // ← 分割したVStackを呼び出す
            .padding()
            .navigationTitle("質問詳細")
            .navigationBarTitleDisplayMode(.inline)
            // --- ★★★ ここから通報用ツールバー (前回提案) ★★★ ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            if authViewModel.isSignedIn {
                                showingReportAlert = true
                            } else {
                                // ログインしていなければログインシートを表示
                                showAuthenticationSheet.wrappedValue = true
                            }
                        } label: {
                            Label("この質問を通報する", systemImage: "exclamationmark.bubble")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            // --- ★★★ ここまで通報用ツールバー ★★★ ---
            
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
                    .environmentObject(authViewModel) // ★ 遷移先にも渡す
                    .environmentObject(profileViewModel) // ★ 遷移先にも渡す
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
                // ★ 通報成功トースト
                if showingReportSuccessToast {
                    Text("通報が完了しました。")
                        .font(.caption)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding(.top, 8)
                }
            }
            // ★ 通報確認アラート
            .alert("通報の確認", isPresented: $showingReportAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("通報する", role: .destructive) {
                    // 通報処理を実行
                    Task {
                        isReporting = true
                        let success = await profileViewModel.reportContent(
                            targetId: question.questionId,
                            targetType: "question",
                            reason: "inappropriate", // 理由はアプリ側で固定 or 選択させる
                            detail: "（ユーザーによる詳細報告なし）"
                        )
                        isReporting = false
                        if success {
                            // 成功トーストを表示
                            withAnimation { showingReportSuccessToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showingReportSuccessToast = false }
                            }
                        } else {
                            // TODO: 失敗アラートを表示
                            print("通報に失敗しました")
                        }
                    }
                }
            } message: {
                Text("「\(question.title)」を不適切なコンテンツとして通報しますか？")
            }
            .task {
                quizViewModel.setAuthViewModel(authViewModel)
            }
    } // End body

    
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
