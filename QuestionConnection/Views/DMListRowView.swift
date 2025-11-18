import SwiftUI

struct DMListRowView: View {
    let thread: Thread
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let isFavorite: Bool
    let lastMessage: String?
    let lastMessageDate: Date?

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
    
    private var opponentProfileImageUrl: String? {
        guard let opponentId else { return nil }
        return profileViewModel.userProfileImages[opponentId]
    }

    // ★★★ 修正：デバッグ出力付き ★★★
    private var isUnread: Bool {
        guard let myUserId = authViewModel.userSub else { return false }
        
        // ★★★ デバッグ出力 ★★★
        let unread = ThreadReadTracker.shared.isUnread(
            threadLastUpdated: thread.lastUpdated,
            userId: myUserId,
            threadId: thread.threadId
        )
        print("🔍 [DMListRowView] threadId: \(thread.threadId), isUnread: \(unread), lastUpdated: \(thread.lastUpdated)")
        
        return unread
    }
    
    // ★★★ メッセージ日付を日本語フォーマット ★★★
    private var formattedMessageDate: String {
        guard let date = lastMessageDate else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "JST")
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        if calendar.isDateInYesterday(date) {
            return "昨日"
        }
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "JST")
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // ★★★ プロフィール画像 ★★★
            if let imageUrl = opponentProfileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
                placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(opponentNicknameDisplay)
                        .foregroundColor(nicknameColor)
                        .lineLimit(1)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    if !formattedMessageDate.isEmpty {
                        Text(formattedMessageDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let message = lastMessage {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("メッセージなし")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // ★★★ 修正：未読ドット常に表示判定 ★★★
            VStack(alignment: .trailing, spacing: 8) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                }
                
                // ★★★ 修正：未読ドットを常に表示判定 ★★★
                if isUnread {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .accessibilityLabel("未読")
                } else {
                    // ★★★ 追加：読済みの場合は空白 ★★★
                    Color.clear
                        .frame(width: 10, height: 10)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .task {
            guard let opponentId else { return }
            // ★★★ 修正：常に fetchNicknameAndImage を呼ぶ ★★★
            _ = await profileViewModel.fetchNicknameAndImage(userId: opponentId)
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
