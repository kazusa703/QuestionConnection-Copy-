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
                        Text("全問正解した問題の出題者には\nすでにDMを送信済みです")
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
                    recipientId: item.authorId,
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

        // myGradedAnswers が空の場合は取得（引数なし）
        if profileViewModel.myGradedAnswers.isEmpty {
            await profileViewModel.fetchMyGradedAnswers()
        }

        pendingManager.fetchPendingDMs(
            myUserId: myUserId,
            answersLogs: profileViewModel.myGradedAnswers,
            dmThreads: dmViewModel.threads
        )
    }
}

struct PendingDMRowView: View {
    let item: PendingDMItem
    @ObservedObject var profileViewModel: ProfileViewModel
    let onSendTap: () -> Void

    @State private var authorNickname: String = "読み込み中..."
    @State private var authorProfileImageUrl: String? = nil

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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // プロフィール画像
                if let imageUrl = authorProfileImageUrl,
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
                    Text(authorNickname)
                        .font(.headline)

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
                        Text("正解日: \(formattedDate)")
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
            await loadAuthorInfo()
        }
    }

    private func loadAuthorInfo() async {
        let result = await profileViewModel.fetchNicknameAndImage(userId: item.authorId)
        authorNickname = result.nickname.isEmpty ? "（未設定）" : result.nickname
        authorProfileImageUrl = result.imageUrl
    }

    private var defaultIcon: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray.opacity(0.5))
    }
}
