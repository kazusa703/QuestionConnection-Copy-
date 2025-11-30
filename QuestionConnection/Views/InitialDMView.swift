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
    
    // ★★★ 修正: Thread -> DMThread に変更 ★★★
    @State private var pendingThread: DMThread? = nil
    @State private var navigateToThread: DMThread? = nil

    // 表示用のトピック文（同じなら非表示）
    private var topicText: String? {
        let t = questionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let nick = recipientNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if t == nick { return nil }
        return "(\(t))"
    }

    var body: some View {
        VStack(spacing: 15) {
            // 全問正解した質問タイトルを表示
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("全問正解しました！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(questionTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .border(Color.green.opacity(0.3), width: 1)
            }
            .padding(.bottom, 8)
            
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
                .border(Color.gray.opacity(0.4), width: 0.5)
                .frame(minHeight: 160)

            Button(action: sendDM) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("送信")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)

            Spacer()
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
            ConversationView(thread: thread, viewModel: viewModel)
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            self.recipientNickname = await profileViewModel.fetchNickname(userId: recipientId)
        }
    }

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
            // ここで返ってくるのは DMThread? なので、pendingThread も DMThread? 型である必要があります
            let thread = await viewModel.sendInitialDMAndReturnThread(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: questionTitle,
                messageText: text
            )
            if let thread {
                let seenAt = Date().addingTimeInterval(1)
                ThreadReadTracker.shared.markSeen(userId: senderId, threadId: thread.threadId, date: seenAt)
                self.pendingThread = thread
                alertTitle = "送信完了"
                alertMessage = "メッセージを送信しました。OKで会話に移動します。"
            } else {
                alertTitle = "エラー"
                alertMessage = "メッセージの送信に失敗しました。"
            }
            showAlert = true
        }
    }
}
