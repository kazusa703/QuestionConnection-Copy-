import SwiftUI

/// DMスレッド一覧 1 行分
/// - 役割: 相手ユーザーのニックネーム表示 / 質問タイトル表示 / 未読インジケータ表示
/// - ニックネーム取得戦略:
///    1) キャッシュ (profileViewModel.userNicknames)
///    2) キャッシュ未取得なら .task で一度だけ fetchNickname
///    3) 取得結果が空文字 -> 「（未設定）」
///    4) 取得失敗（fetchNickname が "" を返し続ける想定） -> 「(削除されたユーザー)」
///       （失敗直後は一時的に "読み込み中..." → 2回目以降で空文字なら未設定、それでも表示されない場合は削除扱い など
///        ここでは簡易に空文字=未設定、nilで試行後も永続的に取得されないケース=削除扱いとする）
///
///  fetchNickname は ProfileViewModel 側で
///   - in-flight Task 共有
///   - 失敗クールダウン
/// を実装している前提。
struct DMListRowView: View {
    let thread: Thread
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

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
                return "（未設定）"
            } else {
                return cached
            }
        }

        // キャッシュ未取得
        // → 初回: 読み込み中表示（.task で取得開始）
        // 取得に失敗しても fetchNickname が空文字をキャッシュする実装なら上で（未設定）になる
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
