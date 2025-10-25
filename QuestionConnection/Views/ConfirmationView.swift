import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss // ConfirmationView自身を閉じる

    // 親の認証シート (AuthenticationSheetView) を閉じるためのBinding
    @Binding var showingAuthSheet: Bool

    let email: String // 前の画面から渡されるメールアドレス
    @State private var confirmationCode = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("本人確認")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(email) に届いた6桁のコードを入力してください。")
                .multilineTextAlignment(.center)

            TextField("確認コード", text: $confirmationCode)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .onChange(of: confirmationCode) { // 入力文字数を6桁に制限
                    if confirmationCode.count > 6 {
                        confirmationCode = String(confirmationCode.prefix(6))
                    }
                }

            Button { // 確認ボタンのアクション
                isLoading = true
                Task {
                    let success = await authViewModel.confirmSignUp(email: email, code: confirmationCode)
                    isLoading = false
                    if success {
                        // ★★★ メッセージを変更 ★★★
                        alertMessage = "登録が完了しました！ログイン画面からログインしてください。"
                    } else {
                        alertMessage = "コードが間違っているか、有効期限が切れています。"
                    }
                    showAlert = true // アラートを表示
                }
            } label: {
                // ローディング表示
                if isLoading { ProgressView() } else { Text("確認") }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || confirmationCode.count != 6) // ローディング中か6桁未入力なら無効

            Spacer() // コンテンツを上に寄せる
        }
        .padding()
        .navigationBarBackButtonHidden(true) // 標準の戻るボタンは非表示
        .alert("本人確認", isPresented: $showAlert) {
            // アラートのOKボタン
            Button("OK") {
                // ★★★ 成功時は親シートも閉じる (変更なし) ★★★
                if alertMessage.contains("完了しました") {
                    dismiss() // ConfirmationViewを閉じる
                    showingAuthSheet = false // 親のAuthenticationSheetViewを閉じる
                }
            }
        } message: {
            Text(alertMessage) // 設定したメッセージを表示
        }
    }
}

// --- プレビュー用のコード ---
#Preview {
    // @State 変数をラッパー構造体の中で宣言する
    struct PreviewWrapper: View {
        @StateObject var authVM = AuthViewModel() // Use @StateObject for preview VM
        @State var dummyShowingSheet = true

        var body: some View {
            // ConfirmationViewに渡す引数を修正
            ConfirmationView(showingAuthSheet: $dummyShowingSheet, email: "test@example.com")
                .environmentObject(authVM)
        }
    }

    return PreviewWrapper() // ラッパービューを返す
}
