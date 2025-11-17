import SwiftUI

struct DMListRowView: View {
    let thread: Thread
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // ★★★ 修正：親からお気に入り状態を受け取る ★★★
    let isFavorite: Bool

    // MARK: - 相手ユーザーID
    private var opponentId: String? {
        guard let myUserId = authViewModel.userSub else { return nil }
        return thread.participants.first(where: { $0 != myUserId })
    }

    // MARK: - ニックネーム表示用文字列
    private var opponentNicknameDisplay: String {
        guard let opponentId else { return "不明なユーザー" }

        // キャッシュ参照
        if let cached = profileViewModel.userNicknames[opponentId] {
            if cached.isEmpty {
                // ★★★ 修正：「（未設定）」に統一 ★★★
                return "（未設定）"
            } else {
                return cached
            }
        }

        return "読み込み中..."
    }

    // MARK: - 未読判定
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
            // ★★★ お気に入り★アイコン ★★★
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(opponentNicknameDisplay)
                    .foregroundColor(nicknameColor)
                    .lineLimit(1)

                Text("Q: \(thread.questionTitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("未読")
            }
        }
        .contentShape(Rectangle()) // 行全体をタップ領域に
        .padding(.vertical, 4)
        .task {
            // キャッシュが無くて opponentId があり、現在取得中でない場合のみ取得を開始
            guard let opponentId,
                  profileViewModel.userNicknames[opponentId] == nil else { return }
            _ = await profileViewModel.fetchNickname(userId: opponentId)
        }
    }

    // MARK: - ニックネーム色
    private var nicknameColor: Color {
        switch opponentNicknameDisplay {
        case "読み込み中...":
            return .secondary
        case "(削除されたユーザー)":
            return .secondary
        case "（未設定）":
            return .secondary
        default:
            return .primary
        }
    }
}
