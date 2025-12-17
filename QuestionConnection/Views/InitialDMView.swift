import SwiftUI

struct InitialDMView: View {
    @StateObject private var viewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // NavigationManager
    @EnvironmentObject var navManager: NavigationManager
    
    @Environment(\.dismiss) private var dismiss

    let recipientId: String
    let questionTitle: String

    @State private var messageText = ""
    @State private var recipientNickname = "読み込み中..."
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var sentThread: DMThread? = nil

    private var topicText: String? {
        let t = questionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let nick = recipientNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if t == nick { return nil }
        return "(\(t))"
    }

    var body: some View {
        VStack(spacing: 15) {
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
            // ★★★ 修正箇所: OKボタンでDM一覧へ移動（会話画面は開かない） ★★★
            Button("OK") {
                if alertTitle == "送信完了" {
                    // 1. このシートを閉じる
                    dismiss()
                    
                    // 2. DMタブ(index: 2)へ切り替える
                    navManager.tabSelection = 2
                    
                    // ※ 会話画面への自動遷移(.append)は削除しました
                }
            }
        } message: {
            Text(alertMessage)
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
            let thread = await viewModel.sendInitialDMAndReturnThread(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: questionTitle,
                messageText: text
            )
            
            if let thread = thread {
                let seenAt = Date().addingTimeInterval(1)
                ThreadReadTracker.shared.markSeen(userId: senderId, threadId: thread.threadId, date: seenAt)
                
                self.sentThread = thread
                alertTitle = "送信完了"
                alertMessage = "メッセージを送信しました。OKでDM一覧に戻ります。"
            } else {
                alertTitle = "エラー"
                alertMessage = "メッセージの送信に失敗しました。"
            }
            showAlert = true
        }
    }
}
