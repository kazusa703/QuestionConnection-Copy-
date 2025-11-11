import SwiftUI
import UIKit

/// 設定画面に表示する「ユーザー情報」セクション
/// - メール: IDトークンの email クレームから取得
/// - ニックネーム: ProfileViewModel の fetchNickname を使用（キャッシュ対応前提）
struct AccountInfoSection: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

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
                    .contextMenu {
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
        .task {
            await loadUserInfo()
        }
        .onChange(of: authViewModel.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await loadUserInfo() }
            } else {
                email = "-"
                nickname = "-"
            }
        }
    }

    // MARK: - Helpers

    private func loadUserInfo() async {
        guard authViewModel.isSignedIn else {
            email = "-"
            nickname = "-"
            return
        }

        // ニックネーム
        if let myUserId = authViewModel.userSub {
            if let cached = profileViewModel.userNicknames[myUserId] {
                nickname = cached.isEmpty ? "（未設定）" : cached
            } else {
                let name = await profileViewModel.fetchNickname(userId: myUserId)
                nickname = name.isEmpty ? "（未設定）" : name
            }
        } else {
            nickname = "-"
        }

        // メール（IDトークンから email クレームを抽出）
        if let token = await authViewModel.getValidIdToken(),
           let mail = extractEmail(fromIDToken: token) {
            email = mail
        } else {
            email = "-"
        }
    }

    private func extractEmail(fromIDToken token: String) -> String? {
        // JWT のペイロード部分（中央）を Base64URL デコードして email を取り出す
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payloadB64 = String(parts[1])
        guard let data = Data(base64URLEncoded: payloadB64) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["email"] as? String
    }
}

private extension Data {
    // Base64URL デコード（= と / + の差異を吸収）
    init?(base64URLEncoded input: String) {
        var s = input.replacingOccurrences(of: "-", with: "+")
                      .replacingOccurrences(of: "_", with: "/")
        let rem = s.count % 4
        if rem > 0 {
            s.append(String(repeating: "=", count: 4 - rem))
        }
        guard let d = Data(base64Encoded: s) else { return nil }
        self = d
    }
}
