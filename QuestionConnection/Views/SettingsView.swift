import SwiftUI
import UserNotifications // ★ 通知許可のために必要

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    // ★★★ 削除失敗時用のアラートを追加 ★★★
    @State private var showingDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    // ★★★ 公開したURLをここに追加 ★★★
    private let termsURL = URL(string: "https://kazusa703.github.io/QuestionConnection-Copy-/terms.md")!
    private let privacyURL = URL(string: "https://kazusa703.github.io/QuestionConnection-Copy-/privacy.md")!


    var body: some View {
        Form {
            // (通知設定セクションは変更なし)
            Section(header: Text("通知設定")) {
                Toggle("全問正解の通知を受け取る", isOn: $profileViewModel.notifyOnCorrectAnswer)
                    .onChange(of: profileViewModel.notifyOnCorrectAnswer) { _, newValue in
                        Task {
                            await profileViewModel.updateNotificationSetting(isOn: newValue)
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
            
            AccountInfoSection()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
            
            // --- ★★★ 情報セクション (URLを修正) ★★★ ---
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
                await profileViewModel.fetchNotificationSettings()
            }
        }
        // ★★★ 削除確認アラート (ロジック修正) ★★★
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
                        // ★★★ 失敗時のアラート文言を設定 ★★★
                        deleteErrorMessage = "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
                        showingDeleteErrorAlert = true
                        isDeleting = false
                    }
                }
            }
        } message: {
            Text("この操作は元に戻せません。アカウントに関連するすべてのデータ（ブックマーク、DMなど）が削除されます。本当に削除しますか？")
        }
        // ★★★ 削除失敗時アラート ★★★
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
