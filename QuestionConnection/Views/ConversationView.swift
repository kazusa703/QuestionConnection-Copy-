import SwiftUI

struct ConversationView: View {
    @StateObject private var viewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel

    let thread: Thread
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == authViewModel.userSub {
                                    Spacer()
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.15))
                                        .cornerRadius(8)
                                } else {
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(8)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.messages.count) { _ in
                        if let uid = authViewModel.userSub {
                            ThreadReadTracker.shared.markSeen(userId: uid, threadId: thread.threadId)
                        }
                        if let last = viewModel.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }

            HStack {
                TextField("メッセージを入力", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("送信") { sendMessage() }
                    .buttonStyle(.borderedProminent)
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("会話")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.setAuthViewModel(authViewModel)
            await viewModel.fetchMessages(threadId: thread.threadId)
        }
        .onAppear {
            if let uid = authViewModel.userSub {
                ThreadReadTracker.shared.markSeen(userId: uid, threadId: thread.threadId)
            }
        }
    }

    private func sendMessage() {
        guard let senderId = authViewModel.userSub,
              let recipientId = thread.participants.first(where: { $0 != senderId }) else {
            print("エラー：送信に必要な情報が不足しています。")
            return
        }

        let textToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }
        self.messageText = ""

        Task {
            let success = await viewModel.sendMessage(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: thread.questionTitle,
                messageText: textToSend
            )
            if success {
                // 送信成功時点で既読化（+1sでサーバー時刻に追従）
                let seenAt = Date().addingTimeInterval(1)
                ThreadReadTracker.shared.markSeen(userId: senderId, threadId: thread.threadId, date: seenAt)

                await viewModel.fetchMessages(threadId: thread.threadId)
                if let uid = authViewModel.userSub {
                    ThreadReadTracker.shared.markSeen(userId: uid, threadId: thread.threadId)
                }
            } else {
                self.messageText = textToSend
            }
        }
    }
}
