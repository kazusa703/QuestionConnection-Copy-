import SwiftUI
import UserNotifications // ★ 通知許可のために必要

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    @State private var showingDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    private let termsURL = URL(string: "https://kazusa703.github.io/QuestionConnection-Copy-/terms.md")!
    private let privacyURL = URL(string: "https://kazusa703.github.io/QuestionConnection-Copy-/privacy.md")!


    var body: some View {
        Form {
            // ★★★ 1. 通知設定セクションを修正 ★★★
            Section(header: Text("通知設定")) {
                // 既存のトグル
                Toggle("全問正解の通知を受け取る", isOn: $profileViewModel.notifyOnCorrectAnswer)
                    .onChange(of: profileViewModel.notifyOnCorrectAnswer) { _, newValue in
                        Task {
                            // 既存のメソッドを呼ぶ
                            await profileViewModel.updateNotificationSetting(isOn: newValue)
                        }
                    }
                
                // ★★★ 2. DM通知用のトグルを追加 ★★★
                Toggle("DMが来たら通知を受け取る", isOn: $profileViewModel.notifyOnDM)
                    .onChange(of: profileViewModel.notifyOnDM) { _, newValue in
                        Task {
                            // 新しく追加したメソッドを呼ぶ
                            await profileViewModel.updateDMNotificationSetting(isOn: newValue)
                        }
                    }
            }

            // (アカウント操作セクションは変更なし)
            Section(header: Text("アカウント操作")) {
                Button(role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("ログアウト")
                        Spacer()
                    }
                }
                .disabled(isDeleting)

                Button(role: .destructive) {
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
                .disabled(isDeleting)
            }
            
            // (AccountInfoSection, 情報セクションは変更なし)
            AccountInfoSection()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
            
            Section(header: Text("情報")) {
                Link("利用規約", destination: termsURL)
                Link("プライバシーポリシー", destination: privacyURL)
                Text("アプリバージョン 1.0.0").foregroundColor(.secondary)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                // ★★★ 3. onAppearで両方の設定を読み込む ★★★
                // (fetchNotificationSettings が両方読み込むように変更済み)
                await profileViewModel.fetchNotificationSettings()
            }
        }
        // (アラート関連は変更なし)
        .alert("アカウントの削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                isDeleting = true
                Task {
                    let success = await profileViewModel.deleteAccount()
                    if success {
                        authViewModel.signOut()
                        isDeleting = false
                        dismiss()
                    } else {
                        deleteErrorMessage = "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
                        showingDeleteErrorAlert = true
                        isDeleting = false
                    }
                }
            }
        } message: {
            Text("この操作は元に戻せません。アカウントに関連するすべてのデータ（ブックマーク、DMなど）が削除されます。本当に削除しますか？")
        }
        .alert("削除エラー", isPresented: $showingDeleteErrorAlert) {
            Button("OK") { }
        } message: {
            Text(deleteErrorMessage)
        }
    }
}


// --- プレビュー (変更なし) ---
#Preview {
    NavigationStack {
        let authVM = AuthViewModel()
        let profileVM = ProfileViewModel(authViewModel: authVM)
        
        SettingsView()
            .environmentObject(authVM)
            .environmentObject(profileVM)
    }
}
