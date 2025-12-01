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
            // ★★★ 通知設定セクション (修正版) ★★★
            Section(header: Text("通知設定")) {
                // 1. 全問正解
                Toggle("全問正解の通知を受け取る", isOn: $profileViewModel.notifyOnCorrectAnswer)
                    .onChange(of: profileViewModel.notifyOnCorrectAnswer) { _, newValue in
                        Task { await profileViewModel.updateNotificationSetting(isOn: newValue) }
                    }
                
                // 2. 記述式の採点結果 (★新規追加)
                Toggle("記述式問題の採点結果を受け取る", isOn: $profileViewModel.notifyOnGradeResult)
                    .onChange(of: profileViewModel.notifyOnGradeResult) { _, newValue in
                        Task { await profileViewModel.updateGradeNotificationSetting(isOn: newValue) }
                    }
                
                // 3. DM受信
                Toggle("DMが来たら通知を受け取る", isOn: $profileViewModel.notifyOnDM)
                    .onChange(of: profileViewModel.notifyOnDM) { _, newValue in
                        Task { await profileViewModel.updateDMNotificationSetting(isOn: newValue) }
                    }
            }

            // (アカウント操作セクション)
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
            
            // (AccountInfoSection)
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
                // onAppearで通知設定を読み込む
                await profileViewModel.fetchNotificationSettings()
                
                // --- ★★★ 通知状態確認 ★★★
                checkNotificationStatus()
                // --- ★★★ ここまで ★★★
            }
        }
        // (アラート関連)
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
    
    // --- ★★★ ヘルパー関数 ★★★
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                print("✅ [SettingsView] APNs: 既に許可されています。")
                // 許可されている場合は、念のためトークン登録を再度試みる
                DispatchQueue.main.async {
                     UIApplication.shared.registerForRemoteNotifications()
                }
            } else if settings.authorizationStatus == .denied {
                print("❌ [SettingsView] APNs: 拒否されています。設定アプリで許可が必要です。")
            } else {
                print("❓ [SettingsView] APNs: まだ許可を求めていません (status: \(settings.authorizationStatus.rawValue))。")
            }
        }
    }
}


// --- プレビュー ---
#Preview {
    NavigationStack {
        let authVM = AuthViewModel()
        let profileVM = ProfileViewModel(authViewModel: authVM)
        
        SettingsView()
            .environmentObject(authVM)
            .environmentObject(profileVM)
    }
}
