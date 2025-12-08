import SwiftUI

struct DMListRowView: View {
    let thread: DMThread
    @ObservedObject var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let isFavorite: Bool
    let lastMessagePreview: String?
    
    // ★ 追加: キャッシュ回避用の一意なID
    // Viewが再生成されるたびに変わるので、常に最新の画像を読みに行きます
    @State private var cacheBuster = UUID().uuidString
    
    private var opponentId: String? {
        guard let myUserId = authViewModel.userSub else { return nil }
        return thread.participants.first(where: { $0 != myUserId })
    }

    private var opponentNicknameDisplay: String {
        guard let opponentId else { return "不明なユーザー" }

        if let cached = profileViewModel.userNicknames[opponentId] {
            return cached.isEmpty ? "（未設定）" : cached
        }
        return "読み込み中..."
    }
    
    private var opponentProfileImageUrl: String? {
        guard let opponentId else { return nil }
        return profileViewModel.userProfileImages[opponentId]
    }

    private var isUnread: Bool {
        guard let myUserId = authViewModel.userSub else { return false }
        return ThreadReadTracker.shared.isUnread(
            threadLastUpdated: thread.lastUpdated,
            userId: myUserId,
            threadId: thread.threadId
        )
    }
    
    private var formattedMessageDate: String {
        let isoString = thread.lastUpdated
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = f.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else {
            return ""
        }
        
        let calendar = Calendar.current
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
        HStack(alignment: .center, spacing: 12) {
            // --- プロフィール画像表示 ---
            if let imageUrl = opponentProfileImageUrl,
               // ★ 修正: URLにクエリパラメータをつけてキャッシュを無効化
               let url = URL(string: "\(imageUrl)?v=\(cacheBuster)") {
                
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        // 読み込み失敗時はデフォルトアイコン
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray)
                    case .empty:
                        // 読み込み中
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                // 背景色をつけて、画像が透過PNGだった場合などに備える
                .background(Circle().fill(Color.gray.opacity(0.1)))
                
            } else {
                // URLがない場合のデフォルト
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
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

                Text(lastMessagePreview ?? "...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                }
                
                if isUnread {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .accessibilityLabel("未読")
                } else {
                    Color.clear
                        .frame(width: 10, height: 10)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .task {
            // 表示されたタイミングで確実に最新情報を取得しにいく
            guard let opponentId else { return }
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
