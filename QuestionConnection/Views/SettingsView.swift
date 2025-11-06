import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    // ★★★ 1. ProfileViewModel を受け取る ★★★
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss // dismiss を取得

    var body: some View {
        Form {
            // ★★★ 2. 「並列1」をトグルスイッチに変更 ★★★
            Section(header: Text("通知設定")) {
                // profileViewModel.notifyOnCorrectAnswer は ProfileViewModel 側で定義する必要がある
                // もし ProfileViewModel に notifyOnCorrectAnswer がまだ無い場合は、
                // 先に ProfileViewModel への追加が必要になります。
                Toggle("全問正解の通知を受け取る", isOn: $profileViewModel.notifyOnCorrectAnswer)
                    .onChange(of: profileViewModel.notifyOnCorrectAnswer) { _, newValue in
                        // トグルが変更されたらAPIを呼び出す
                        Task {
                            await profileViewModel.updateNotificationSetting(isOn: newValue)
                        }
                    }
            }

            // 「並列２」はスニペットのコメントに基づき削除しました。

            // --- アカウント操作セクション (変更なし) ---
            Section {
                Button(role: .destructive) {
                    // 1. ログアウトを実行
                    authViewModel.signOut()
                    // ★★★ 2. SettingsView を閉じる ★★★
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("ログアウト")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        // ★★★ 3. 画面表示時に現在の設定を読み込む ★★★
        .onAppear {
            Task {
                await profileViewModel.fetchNotificationSettings()
            }
        }
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

