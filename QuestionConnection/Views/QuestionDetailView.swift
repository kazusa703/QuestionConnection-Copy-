import SwiftUI
import UIKit

struct QuestionDetailView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    @State private var showingReportAlert = false
    @State private var showingReportSuccessToast = false
    @State private var showingBlockAlert = false
    @State private var showingBlockSuccessToast = false
    @State private var showingUnblockSuccessToast = false
    @State private var isProcessingAction = false

    let question: Question
    @State private var hasAnswered: Bool? = nil
    @State private var shouldNavigateToQuiz = false
    @State private var showCopiedToast = false

    // (isBookmarked, isAuthorNotMe, isAuthorBlocked は変更なし)
    private var isBookmarked: Bool {
        profileViewModel.isBookmarked(questionId: question.id)
    }
    
    private var isAuthorNotMe: Bool {
        authViewModel.isSignedIn && authViewModel.userSub != question.authorId
    }
    
    private var isAuthorBlocked: Bool {
        profileViewModel.isBlocked(userId: question.authorId)
    }

    // --- contentBody (変更なし) ---
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.title)
                .font(.largeTitle)
                .fontWeight(.bold)

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

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("備考・説明").font(.headline)
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
                .font(.headline)
                .padding()
                .background(buttonBackgroundColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(authViewModel.isSignedIn && (hasAnswered != false || quizViewModel.isLoading))

        } // End VStack
    }
    
    // --- body (ツールバーを修正) ---
    var body: some View {
        contentBody // ← 分割したVStackを呼び出す
            .padding()
            .navigationTitle("質問詳細")
            .navigationBarTitleDisplayMode(.inline)
            
            // --- ★★★ ツールバーを修正 ★★★ ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 1. ブックマークボタン
                        Button(action: toggleBookmark) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? .orange : .gray)
                        }
                        
                        // 2. 既存の通報・ブロックメニュー
                        Menu {
                            Button(role: .destructive) {
                                if authViewModel.isSignedIn {
                                    showingReportAlert = true
                                } else {
                                    showAuthenticationSheet.wrappedValue = true
                                }
                            } label: {
                                Label("この質問を通報する", systemImage: "exclamationmark.bubble")
                            }
                            
                            if isAuthorNotMe { // 自分の質問でなければ
                                Button(role: .destructive) {
                                    if isAuthorBlocked {
                                        Task {
                                            isProcessingAction = true
                                            await profileViewModel.removeBlock(blockedUserId: question.authorId)
                                            isProcessingAction = false
                                            withAnimation { showingUnblockSuccessToast = true }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                withAnimation { showingUnblockSuccessToast = false }
                                            }
                                        }
                                    } else {
                                        showingBlockAlert = true
                                    }
                                } label: {
                                    if isAuthorBlocked {
                                        Label("ブロックを解除する", systemImage: "hand.thumbsup")
                                    } else {
                                        Label("このユーザーをブロックする", systemImage: "hand.raised.slash")
                                    }
                                }
                                .disabled(isProcessingAction)
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            // --- ★★★ 修正ここまで ★★★ ---
            
            // (残りのモディファイアは変更なし)
            .onAppear {
                quizViewModel.setAuthViewModel(authViewModel)
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
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
            }
            .overlay(alignment: .top) {
                // (各種トースト ... 変更なし)
                if showCopiedToast {
                    Text("コピーしました")
                        .font(.caption2)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding(.top, 8)
                }
                if showingReportSuccessToast {
                    Text("通報が完了しました。")
                        .font(.caption)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding(.top, 8)
                }
                if showingBlockSuccessToast {
                    Text("ブロックしました。")
                        .font(.caption)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding(.top, 8)
                }
                if showingUnblockSuccessToast {
                    Text("ブロックを解除しました。")
                        .font(.caption)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding(.top, 8)
                }
            }
            // (各種アラート ... 変更なし)
            .alert("通報の確認", isPresented: $showingReportAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("通報する", role: .destructive) {
                    Task {
                        isProcessingAction = true
                        let success = await profileViewModel.reportContent(
                            targetId: question.questionId,
                            targetType: "question",
                            reason: "inappropriate",
                            detail: "（ユーザーによる詳細報告なし）"
                        )
                        isProcessingAction = false
                        if success {
                            withAnimation { showingReportSuccessToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showingReportSuccessToast = false }
                            }
                        } else {
                            // TODO: 失敗アラート
                        }
                    }
                }
            } message: {
                Text("「\(question.title)」を不適切なコンテンツとして通報しますか？")
            }
            .alert("ブロックの確認", isPresented: $showingBlockAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("ブロックする", role: .destructive) {
                    Task {
                        isProcessingAction = true
                        let success = await profileViewModel.addBlock(blockedUserId: question.authorId)
                        isProcessingAction = false
                        if success {
                            withAnimation { showingBlockSuccessToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showingBlockSuccessToast = false }
                            }
                        } else {
                            // TODO: 失敗アラート
                        }
                    }
                }
            } message: {
                Text("このユーザーをブロックしますか？\n（ブロックした相手からのDMが拒否されます）")
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
    
    // --- ★★★ 追加：ブックマークトグル関数 ★★★ ---
    private func toggleBookmark() {
        guard authViewModel.isSignedIn else {
            showAuthenticationSheet.wrappedValue = true
            return
        }
        
        Task {
            if isBookmarked {
                await profileViewModel.removeBookmark(questionId: question.id)
            } else {
                await profileViewModel.addBookmark(questionId: question.id)
            }
        }
    }
    // --- ★★★ 追加完了 ★★★ ---
}
