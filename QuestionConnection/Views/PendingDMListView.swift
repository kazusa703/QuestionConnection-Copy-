import SwiftUI

struct PendingDMListView: View {
    @StateObject private var pendingManager = PendingDMManager()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @StateObject private var dmViewModel = DMViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PendingDMItem? = nil

    var body: some View {
        NavigationStack {
            Group {
                if pendingManager.isLoading {
                    ProgressView("読み込み中...")
                } else if pendingManager.pendingDMs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("未送信のDMはありません")
                            .font(.headline)
                        // ★★★ 修正: メッセージを変更 ★★★
                        Text("DMが可能な相手には\nすでにメッセージを送信済みです")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(pendingManager.pendingDMs) { item in
                            PendingDMRowView(
                                item: item,
                                profileViewModel: profileViewModel,
                                onSendTap: {
                                    selectedItem = item
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("DM未送信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                InitialDMView(
                    recipientId: item.recipientId,  // ★ 変更: authorId → recipientId
                    questionTitle: item.questionTitle
                )
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        guard let myUserId = authViewModel.userSub else { return }

        dmViewModel.setAuthViewModel(authViewModel)
        await dmViewModel.fetchThreads(userId: myUserId)

        // 自分が回答した履歴を取得
        if profileViewModel.myGradedAnswers.isEmpty {
            await profileViewModel.fetchMyGradedAnswers()
        }
        
        // ★★★ 追加: 自分の質問への回答履歴（出題者として）も取得 ★★★
        // answerLogs は自分が作った質問への回答
        // 既に取得済みならそのまま使用
        
        pendingManager.fetchPendingDMs(
            myUserId: myUserId,
            myAnswersLogs: profileViewModel.myGradedAnswers,      // 回答者として
            authorAnswersLogs: profileViewModel.answerLogs,       // 出題者として
            dmThreads: dmViewModel.threads
        )
    }
}

struct PendingDMRowView: View {
    let item: PendingDMItem
    @ObservedObject var profileViewModel: ProfileViewModel
    let onSendTap: () -> Void

    @State private var recipientNickname: String = "読み込み中..."
    @State private var recipientProfileImageUrl: String? = nil

    private var formattedDate: String {
        let isoString = item.completedAt
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ja_JP")
        displayFormatter.dateFormat = "M月d日"
        return displayFormatter.string(from: date)
    }
    
    // ★★★ 追加: 役割に応じたラベル ★★★
    private var roleLabel: String {
        switch item.role {
        case .answerer:
            return "あなたが全問正解"
        case .author:
            return "あなたが正解にした"
        }
    }
    
    private var roleLabelColor: Color {
        switch item.role {
        case .answerer:
            return .green
        case .author:
            return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // プロフィール画像
                if let imageUrl = recipientProfileImageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            defaultIcon
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    defaultIcon
                        .frame(width: 50, height: 50)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipientNickname)
                        .font(.headline)
                    
                    // ★★★ 追加: 役割ラベル ★★★
                    Text(roleLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(roleLabelColor.opacity(0.1))
                        .foregroundColor(roleLabelColor)
                        .cornerRadius(4)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(item.questionTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if !formattedDate.isEmpty {
                        Text(item.role == .answerer ? "正解日: \(formattedDate)" : "採点日: \(formattedDate)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }

            Button(action: onSendTap) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("DMを送る")
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .task {
            await loadRecipientInfo()
        }
    }

    private func loadRecipientInfo() async {
        let result = await profileViewModel.fetchNicknameAndImage(userId: item.recipientId)
        recipientNickname = result.nickname.isEmpty ? "（未設定）" : result.nickname
        recipientProfileImageUrl = result.imageUrl
    }

    private var defaultIcon: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray.opacity(0.5))
    }
}
