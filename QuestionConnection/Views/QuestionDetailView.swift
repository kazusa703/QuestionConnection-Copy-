import SwiftUI
import UIKit

struct QuestionDetailView: View {
    @StateObject private var quizViewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    // アラート・シート管理
    @State private var showReportSheet = false
    @State private var showingReportSuccessToast = false
    @State private var showingBlockAlert = false
    @State private var showingBlockSuccessToast = false
    @State private var showingUnblockSuccessToast = false
    
    // コピー完了トースト
    @State private var showCopiedToast = false
    
    // アクション中フラグ
    @State private var isProcessingAction = false

    let question: Question
    @State private var hasAnswered: Bool? = nil
    @State private var shouldNavigateToQuiz = false

    private var isBookmarked: Bool {
        profileViewModel.isBookmarked(questionId: question.id)
    }
    
    private var isAuthorNotMe: Bool {
        authViewModel.isSignedIn && authViewModel.userSub != question.authorId
    }
    
    private var isAuthorBlocked: Bool {
        profileViewModel.isBlocked(userId: question.authorId)
    }

    // --- contentBody ---
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 出題者情報 (追加)
            HStack {
                // プロフィール画像
                AsyncImage(url: URL(string: profileViewModel.userProfileImages[question.authorId] ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(profileViewModel.getDisplayName(userId: question.authorId))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(formatDate(question.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
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

        }
    }
    
    // --- body ---
    var body: some View {
        contentBody
            .padding()
            .navigationTitle("質問詳細")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 1. ブックマークボタン
                        Button(action: toggleBookmark) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? .orange : .gray)
                        }
                        
                        // 2. メニュー (通報・ブロック・シェアなど)
                        Menu {
                            // シェア
                            Button {
                                // シェア処理 (実装が必要ならここに記述)
                            } label: {
                                Label("シェア", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            // 自分の投稿でない場合のみ表示
                            if isAuthorNotMe {
                                // 通報 (ReportViewへ遷移)
                                Button(role: .destructive) {
                                    if authViewModel.isSignedIn {
                                        showReportSheet = true
                                    } else {
                                        showAuthenticationSheet.wrappedValue = true
                                    }
                                } label: {
                                    Label("この質問を通報する", systemImage: "exclamationmark.bubble")
                                }
                                
                                // ブロック / ブロック解除
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
            .onAppear {
                quizViewModel.setAuthViewModel(authViewModel)
                if authViewModel.isSignedIn {
                    checkAnswerStatus()
                } else {
                    hasAnswered = false
                }
                // 出題者の情報を取得
                Task {
                    _ = await profileViewModel.fetchNicknameAndImage(userId: question.authorId)
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
            // ★★★ 通報シート ★★★
            .sheet(isPresented: $showReportSheet) {
                ReportView(
                    targetType: .question,
                    targetId: question.questionId,
                    targetName: question.title
                ) { success in
                    if success {
                        withAnimation { showingReportSuccessToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { showingReportSuccessToast = false }
                        }
                    }
                }
                .environmentObject(authViewModel)
            }
            // ★★★ ブロック確認アラート ★★★
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
                        }
                    }
                }
            } message: {
                Text("このユーザーをブロックしますか？\n（ブロックした相手からのDMが拒否されます）")
            }
            // ★★★ オーバーレイ (トースト表示) ★★★
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
            .overlay(alignment: .bottom) {
                Group {
                    if showingReportSuccessToast {
                        ToastView(message: "通報を受け付けました", icon: "checkmark.circle.fill")
                    }
                    if showingBlockSuccessToast {
                        ToastView(message: "ブロックしました", icon: "hand.raised.slash.fill")
                    }
                    if showingUnblockSuccessToast {
                        ToastView(message: "ブロックを解除しました", icon: "hand.thumbsup.fill")
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showingReportSuccessToast || showingBlockSuccessToast || showingUnblockSuccessToast)
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "ja_JP")
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// ★★★ トースト表示用View ★★★
struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .padding(.bottom, 30)
    }
}
