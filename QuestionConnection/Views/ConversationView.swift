import SwiftUI

private struct MessageRowView: View {
    let isMine: Bool
    let text: String
    let id: String

    var body: some View {
        HStack {
            if isMine {
                Spacer()
                Text(text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: .trailing)
            } else {
                Text(text)
                    .padding(10)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .id(id)
    }
}

private struct MessageListView: View {
    let messages: [Message]   // Message は id, senderId, text を持つ前提
    let myUserId: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageRowView(
                            isMine: message.senderId == myUserId,
                            text: message.text,
                            id: message.id
                        )
                    }
                }
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

struct ConversationView: View {
    let thread: Thread
    @ObservedObject var viewModel: DMViewModel

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""
    @State private var recipientNickname: String? = nil

    @State private var showingBlockAlert = false
    @State private var showingBlockSuccessToast = false
    @State private var isProcessingAction = false
    @State private var showingSendErrorAlert = false
    @State private var sendErrorMessage = ""

    private var opponentId: String? {
        guard let myUserId = authViewModel.userSub else { return nil }
        return thread.participants.first(where: { $0 != myUserId })
    }

    private var isOpponentBlocked: Bool {
        guard let opponentId = opponentId else { return false }
        return profileViewModel.isBlocked(userId: opponentId)
    }

    private var navigationTitleNickname: String {
        if let nick = recipientNickname { return nick.isEmpty ? "(未設定)" : nick }
        return "読み込み中..."
    }

    private var toolbarMenuButton: some View {
        Menu {
            if let opponentId = opponentId, authViewModel.userSub != opponentId {
                Button(role: isOpponentBlocked ? .none : .destructive) {
                    if isOpponentBlocked {
                        Task {
                            isProcessingAction = true
                            _ = await profileViewModel.removeBlock(blockedUserId: opponentId)
                            isProcessingAction = false
                        }
                    } else {
                        showingBlockAlert = true
                    }
                } label: {
                    if isOpponentBlocked {
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

    var body: some View {
        VStack(spacing: 8) {
            MessageListView(messages: viewModel.messages, myUserId: authViewModel.userSub)
            inputAreaView
        }
        .navigationTitle(navigationTitleNickname)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { toolbarMenuButton }
        }
        .overlay(alignment: .top) {
            if showingBlockSuccessToast {
                Text("ブロックしました。")
                    .font(.caption)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.top, 8)
            }
        }
        .alert("ブロックの確認", isPresented: $showingBlockAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロックする", role: .destructive) {
                guard let opponentId = opponentId else { return }
                Task {
                    isProcessingAction = true
                    let success = await profileViewModel.addBlock(blockedUserId: opponentId)
                    isProcessingAction = false
                    if success {
                        withAnimation { showingBlockSuccessToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { showingBlockSuccessToast = false }
                        }
                        dismiss()
                    }
                }
            }
        } message: {
            Text("このユーザーをブロックしますか？\n（相手からのDMが拒否され、一覧からも非表示になります）")
        }
        .alert("送信エラー", isPresented: $showingSendErrorAlert) {
            Button("OK") {}
        } message: {
            Text(sendErrorMessage)
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            await viewModel.fetchMessages(threadId: thread.threadId)
            if let opponentId = opponentId {
                self.recipientNickname = await profileViewModel.fetchNickname(userId: opponentId)
            }
        }
    }

    private var inputAreaView: some View {
        HStack(spacing: 8) {
            TextField("メッセージを入力", text: $messageText)
                .textFieldStyle(.roundedBorder)
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func sendMessage() {
        guard let senderId = authViewModel.userSub,
              let recipientId = opponentId else {
            print("送信者または受信者のIDが見つかりません。")
            return
        }
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            let success = await viewModel.sendMessage(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: thread.questionTitle,
                messageText: text
            )
            if success {
                messageText = ""
                await viewModel.fetchMessages(threadId: thread.threadId)
            } else {
                sendErrorMessage = "メッセージの送信に失敗しました。\n相手からブロックされているか、ネットワークに問題がある可能性があります。"
                showingSendErrorAlert = true
            }
        }
    }
}
