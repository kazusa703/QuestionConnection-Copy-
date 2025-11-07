import SwiftUI
import UserNotifications // ★ 通知許可のために必要

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    // ★★★ 1. ProfileViewModel を受け取る ★★★
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss // dismiss を取得

    // ★★★ 2. 削除確認アラート用の状態 ★★★
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false // 削除処理中のインジケータ用

    var body: some View {
        Form {
            // ★★★ 3. 「通知設定」セクションを ProfileViewModel にバインド ★★★
            Section(header: Text("通知設定")) {
                // profileViewModel.notifyOnCorrectAnswer は ProfileViewModel 側で定義済み
                Toggle("全問正解の通知を受け取る", isOn: $profileViewModel.notifyOnCorrectAnswer)
                    .onChange(of: profileViewModel.notifyOnCorrectAnswer) { _, newValue in
                        // トグルが変更されたらAPIを呼び出す
                        Task {
                            // (注: プッシュ通知の許可リクエストは別途 AppDelegate で実装済みのはず)
                            await profileViewModel.updateNotificationSetting(isOn: newValue)
                        }
                    }
            }

            // --- ★★★ 4. アカウント操作セクション (修正指示に基づき更新) ★★★ ---
            Section(header: Text("アカウント操作")) {
                Button(role: .destructive) {
                    // ログアウト処理
                    authViewModel.signOut()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("ログアウト")
                        Spacer()
                    }
                }

                // ★★★ アカウント削除ボタンを追加 ★★★
                Button(role: .destructive) {
                    // 削除確認アラートを表示
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("アカウントを削除する")
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting) // 処理中は無効化
            }
            
            // --- ★★★ 5. 情報セクション (元のコードからマージ) ★★★ ---
            Section(header: Text("情報")) {
                Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
                Text("アプリバージョン 1.0.0").foregroundColor(.secondary)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        // ★★★ 6. 画面表示時に現在の設定を読み込む ★★★
        .onAppear {
            Task {
                await profileViewModel.fetchNotificationSettings()
            }
        }
        // ★★★ 7. 削除確認アラートを追加 ★★★
        .alert("アカウントの削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                // 削除処理を実行
                isDeleting = true
                Task {
                    // ★★★ 修正: ProfileViewModel の deleteAccount を呼び出す ★★★
                    let success = await profileViewModel.deleteAccount()
                    if success {
                        // 成功したらアプリ側でもログアウト（サインアウト）処理
                        authViewModel.signOut()
                        isDeleting = false
                        dismiss() // 設定画面を閉じる
                    } else {
                        // TODO: 失敗アラートを別途表示するのが親切
                        print("アカウント削除に失敗しました。")
                        isDeleting = false
                        // (将来的には ProfileViewModel にエラー状態を持たせてアラート表示)
                    }
                }
            }
        } message: {
            Text("この操作は元に戻せません。アカウントに関連するすべてのデータ（ブックマーク、DMなど）が削除されます。本当に削除しますか？")
        }
        
        // (注: 元のコードにあった showAlert, alertTitle, alertMessage は
        // deleteAccount のロジックが ViewModel に移動したため不要になりました)
    }
}


// --- プレビュー用のコード ---
#Preview {
    // NavigationStackで囲んでプレビュー
    NavigationStack {
        // ★★★ プレビュー用にダミーのViewModelを作成 ★★★
        let authVM = AuthViewModel()
        let profileVM = ProfileViewModel(authViewModel: authVM)
        
        SettingsView()
            .environmentObject(authVM) // ダミーのAuthViewModelを渡す
            .environmentObject(profileVM) // ダミーのProfileViewModelを渡す
    }
}
