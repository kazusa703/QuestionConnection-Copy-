import SwiftUI

/// 設定画面に表示する「ユーザー情報」セクション
struct AccountInfoSection: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel:  ProfileViewModel

    @State private var email: String = "読み込み中..."
    @State private var nickname: String = "読み込み中..."

    var body: some View {
        Section(header: Text("ユーザー情報")) {
            HStack {
                Text("メールアドレス")
                Spacer()
                Text(email)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    . contextMenu {
                        Button("コピー") { UIPasteboard.general.string = email }
                    }
            }
            HStack {
                Text("ニックネーム")
                Spacer()
                Text(nickname.isEmpty ? "（未設定）" : nickname)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .contextMenu {
                        Button("コピー") { UIPasteboard.general.string = nickname }
                    }
            }
        }
        .onAppear {
            loadUserInfoSync()
        }
        .task {
            await loadNicknameAsync()
        }
        .onChange(of: authViewModel.isSignedIn) { _, signedIn in
            if signedIn {
                loadUserInfoSync()
                Task { await loadNicknameAsync() }
            } else {
                email = "-"
                nickname = "-"
            }
        }
    }

    // MARK: - Helpers

    /// 同期的に取得できる情報（メール）
    private func loadUserInfoSync() {
        guard authViewModel.isSignedIn else {
            email = "-"
            nickname = "-"
            return
        }
        
        // メールは authViewModel から直接取得（APIコール不要）
        if let userEmail = authViewModel.userEmail {
            email = userEmail
        } else {
            email = "-"
        }
    }
    
    /// 非同期で取得する情報（ニックネーム）
    private func loadNicknameAsync() async {
        // ★ サインイン状態を再確認
        guard authViewModel.isSignedIn else {
            await MainActor.run {
                nickname = "-"
            }
            return
        }
        
        guard let myUserId = authViewModel.userSub else {
            await MainActor.run {
                nickname = "-"
            }
            return
        }
        
        // キャッシュから取得
        if let cached = profileViewModel.userNicknames[myUserId], !cached.isEmpty {
            await MainActor.run {
                nickname = cached
            }
            return
        }
        
        // APIから取得
        let name = await profileViewModel.fetchNickname(userId: myUserId)
        await MainActor.run {
            nickname = name.isEmpty ? "（未設定）" : name
        }
    }
}
