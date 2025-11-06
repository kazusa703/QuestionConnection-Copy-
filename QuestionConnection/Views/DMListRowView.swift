import SwiftUI

/// DMスレッド一覧の「1行分」を表示するためのビュー
struct DMListRowView: View {
    // DMListViewから渡される情報
    let thread: Thread
    
    // 共有されたViewModelを受け取る
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @EnvironmentObject private var authViewModel: AuthViewModel

    // 相手のニックネーム（キャッシュから取得）
    private var opponentNickname: String {
        guard let myUserId = authViewModel.userSub else { return "認証エラー" }
        // 相手のIDを特定
        guard let opponentId = thread.participants.first(where: { $0 != myUserId }) else {
            return "不明なユーザー"
        }
        return profileViewModel.userNicknames[opponentId] ?? "不明なユーザー"
    }

    // 未読インジケーター判定
    private var isUnread: Bool {
        guard let myUserId = authViewModel.userSub else { return false }
        return ThreadReadTracker.shared.isUnread(
            threadLastUpdated: thread.lastUpdated,
            userId: myUserId,
            threadId: thread.threadId
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // 「相手: 」の接頭辞を削除してユーザー名のみ表示
                Text(opponentNickname)
                    .foregroundColor(.primary)
                Text("Q: \(thread.questionTitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("未読")
            }
        }
        .padding(.vertical, 4)
    }
}
