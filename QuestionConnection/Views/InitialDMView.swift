import SwiftUI

struct InitialDMView: View {
    // ViewModels
    @StateObject private var viewModel = DMViewModel() // DM送信用のViewModel (変更なし)
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // --- ★★★ 追加: 共有されたニックネーム用ViewModelを受け取る ★★★ ---
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // この画面を閉じるための機能
    @Environment(\.dismiss) private var dismiss

    // 前の画面から受け取る情報
    let recipientId: String // 相手のID (Cognito Sub)
    let questionTitle: String

    // 入力フォーム用の状態変数
    @State private var messageText = ""

    // --- ★★★ 追加: 取得したニックネームを保持する ★★★ ---
    @State private var recipientNickname = "読み込み中..."

    // アラート表示用の状態変数
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 15) {
            // --- ★★★ 修正: recipientId の代わりに recipientNickname を表示 ★★★ ---
            Text("\(recipientNickname) さんへのメッセージ")
                .font(.headline)
            // --- ★★★ ここまで ★★★ ---
            
            Text("(\(questionTitle) について)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $messageText)
                .border(Color.gray, width: 0.5)
                .padding()

            Button(action: sendDM) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("送信")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
            .disabled(messageText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .navigationTitle("DM作成")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "送信完了" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        // --- ★★★ 追加: ビュー表示時にニックネームを取得する ★★★ ---
        .task {
            // 必要な情報（idToken）を取得
            guard let idToken = authViewModel.idToken else {
                recipientNickname = "認証エラー"
                return
            }
            // ProfileViewModelを使ってニックネームを取得
            self.recipientNickname = await profileViewModel.fetchNickname(
                userId: recipientId, // 相手のIDを渡す
                idToken: idToken
            )
        }
        // --- ★★★ ここまで ★★★ ---
    }

    // sendDM 関数は変更なし
    private func sendDM() {
        guard let senderId = authViewModel.userSub, let idToken = authViewModel.idToken else {
            alertTitle = "エラー"
            alertMessage = "送信者情報が見つかりません。再ログインしてください。"
            showAlert = true
            return
        }

        Task {
            let success = await viewModel.sendInitialDM(
                recipientId: recipientId,
                senderId: senderId,
                questionTitle: questionTitle,
                messageText: messageText,
                idToken: idToken
            )

            if success {
                alertTitle = "送信完了"
                alertMessage = "メッセージを送信しました。"
            } else {
                alertTitle = "エラー"
                alertMessage = "メッセージの送信に失敗しました。"
            }
            showAlert = true
        }
    }
}
