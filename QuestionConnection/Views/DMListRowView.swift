import SwiftUI

struct DMListRowView: View {
    let thread: Thread
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let isFavorite: Bool

    private var opponentId: String? {
        guard let myUserId = authViewModel.userSub else { return nil }
        return thread.participants.first(where: { $0 != myUserId })
    }

    private var opponentNicknameDisplay: String {
        guard let opponentId else { return "不明なユーザー" }

        if let cached = profileViewModel.userNicknames[opponentId] {
            if cached.isEmpty {
                return "（未設定）"
            } else {
                return cached
            }
        }

        return "読み込み中..."
    }

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
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
            }

            // ★★★ 修正：名前だけを表示 ★★★
            Text(opponentNicknameDisplay)
                .foregroundColor(nicknameColor)
                .lineLimit(1)

            Spacer()
            
            if isUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("未読")
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .task {
            guard let opponentId,
                  profileViewModel.userNicknames[opponentId] == nil else { return }
            _ = await profileViewModel.fetchNickname(userId: opponentId)
        }
    }

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
