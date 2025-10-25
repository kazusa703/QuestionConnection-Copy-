import SwiftUI

struct ConversationView: View {
    // ViewModelを新しくインスタンス化する（StateObjectを使う）
    @StateObject private var viewModel = DMViewModel()
    // アプリ全体で共有されている認証情報にアクセス
    @EnvironmentObject private var authViewModel: AuthViewModel

    // 前の画面(DMListView)から受け取るスレッド情報
    let thread: Thread

    // メッセージ入力欄用の状態変数
    @State private var messageText = ""

    var body: some View {
        VStack {
            // メッセージ表示エリア
            ScrollView {
                ScrollViewReader { proxy in // 特定の位置にスクロールするための機能
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                // 自分のメッセージは右寄せ、相手のは左寄せ
                                if message.senderId == authViewModel.userSub {
                                    Spacer() // 右に押しやるためのスペーサー
                                    Text(message.text)
                                        .padding(12)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                } else {
                                    Text(message.text)
                                        .padding(12)
                                        .background(Color(UIColor.systemGray5))
                                        .cornerRadius(16)
                                    Spacer() // 左に押しやるためのスペーサー
                                }
                            }
                            .id(message.id) // 各メッセージにIDを割り当ててスクロール可能に
                        }
                    }
                    .padding(.horizontal)
                    // 新しいメッセージが追加されたら一番下にスクロールする
                    .onChange(of: viewModel.messages.count) {
                        if let lastMessageId = viewModel.messages.last?.id {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }

            // メッセージ入力・送信エリア
            HStack {
                TextField("メッセージを入力", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(messageText.isEmpty || viewModel.isLoading) // 空欄または送信中は無効化
            }
            .padding()
        }
        .navigationTitle(thread.questionTitle) // ナビゲーションバーのタイトル
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // この画面が表示された時にメッセージ一覧を取得
            fetchMessages()
        }
    }

    // メッセージ一覧を取得する関数
    private func fetchMessages() {
        guard let idToken = authViewModel.idToken else { return }
        Task {
            await viewModel.fetchMessages(threadId: thread.threadId, idToken: idToken)
        }
    }

    // メッセージを送信する関数
    private func sendMessage() {
        guard let senderId = authViewModel.userSub,
              let idToken = authViewModel.idToken,
              // 相手のIDを特定（自分じゃない方の参加者）
              let recipientId = thread.participants.first(where: { $0 != senderId })
        else {
            print("エラー：送信に必要な情報が不足しています。")
            return
        }

        let textToSend = messageText // 送信するテキストを保持
        self.messageText = "" // 入力欄をクリア

        Task {
            let success = await viewModel.sendMessage(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: thread.questionTitle, // スレッド情報から取得
                messageText: textToSend, // 保持しておいたテキスト
                idToken: idToken
            )

            // 送信に成功したら、メッセージリストを再読み込みして最新の状態を表示
            if success {
                fetchMessages()
            } else {
                self.messageText = textToSend // 失敗したら入力欄にテキストを戻す（任意）
            }
        }
    }
}
