import SwiftUI

struct InitialDMView: View {
    @StateObject private var viewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    let recipientId: String
    let questionTitle: String

    @State private var messageText = ""
    @State private var recipientNickname = "読み込み中..."
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var pendingThread: Thread? = nil
    @State private var navigateToThread: Thread? = nil

    // (topicText の計算ロジック ... 変更なし)
    private var topicText: String? {
        let t = questionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let nick = recipientNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if t == nick { return nil }
        return "(\(t) )"
    }

    var body: some View {
        VStack(spacing: 15) {
            Text("\(recipientNickname) さんへのメッセージ")
                .font(.headline)

            if let topic = topicText {
                Text(topic)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            TextEditor(text: $messageText)
                .border(Color.gray, width: 0.5)
                .padding()

            Button(action: sendDM) {
                if viewModel.isLoading { ProgressView() } else { Text("送信") }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding()
        .navigationTitle("DM作成")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "送信完了", let t = pendingThread {
                    navigateToThread = t
                }
            }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(item: $navigateToThread) { thread in
            ConversationView(thread: thread)
                .environmentObject(authViewModel)
        }
        .task {
            // ★★★ 修正: VMにAuthViewModelをセット ★★★
            // (DMViewModel.swift が v5 (ブロック確認機能付き) に更新されている前提)
            viewModel.setAuthViewModel(authViewModel)
            self.recipientNickname = await profileViewModel.fetchNickname(userId: recipientId)
        }
    }

    // --- ★★★ sendDM 関数を修正 (アラートメッセージ) ★★★ ---
    private func sendDM() {
        guard let senderId = authViewModel.userSub else {
            alertTitle = "エラー"
            alertMessage = "送信者情報が見つかりません。再ログインしてください。"
            showAlert = true
            return
        }
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            // v5 の DMViewModel は、ブロックされている場合 nil を返す
            let thread = await viewModel.sendInitialDMAndReturnThread(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: questionTitle,
                messageText: text
            )
            
            if let thread {
                // --- 成功 ---
                let seenAt = Date().addingTimeInterval(1)
                ThreadReadTracker.shared.markSeen(userId: senderId, threadId: thread.threadId, date: seenAt)
                self.pendingThread = thread
                alertTitle = "送信完了"
                alertMessage = "メッセージを送信しました。OKで会話に移動します。"
            } else {
                // --- 失敗 ---
                alertTitle = "送信エラー"
                // ★ 失敗理由に「ブロック」の可能性を明記
                alertMessage = "メッセージの送信に失敗しました。\n相手からブロックされているか、ネットワークに問題がある可能性があります。"
            }
            showAlert = true
        }
    }
}
