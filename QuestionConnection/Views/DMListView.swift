import SwiftUI

struct DMListView: View {
    @StateObject private var dmViewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var searchText = ""
    @State private var isInitialFetchDone = false
    
    @State private var selectedTab: DMTab = .all

    @State private var favoriteThreadIds: Set<String> = []

    enum DMTab {
        case all
        case unread
        case favorite
    }

    private var filteredThreads: [Thread] {
        guard let myUserId = authViewModel.userSub else { return [] }

        let nonBlocked = dmViewModel.threads.filter { thread in
            let opponentId = thread.participants.first(where: { $0 != myUserId }) ?? ""
            return !profileViewModel.isBlocked(userId: opponentId)
        }

        guard !searchText.isEmpty else {
            return applyTabFilter(nonBlocked, myUserId: myUserId)
        }

        let searched = nonBlocked.filter { thread in
            if thread.questionTitle.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            if let opponentId = thread.participants.first(where: { $0 != myUserId }),
               let nickname = profileViewModel.userNicknames[opponentId],
               nickname.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            return false
        }

        return applyTabFilter(searched, myUserId: myUserId)
    }

    private func applyTabFilter(_ threads: [Thread], myUserId: String) -> [Thread] {
        switch selectedTab {
        case .all:
            return threads
        case .unread:
            return threads.filter { thread in
                ThreadReadTracker.shared.isUnread(
                    threadLastUpdated: thread.lastUpdated,
                    userId: myUserId,
                    threadId: thread.threadId
                )
            }
        case .favorite:
            return threads.filter { thread in
                favoriteThreadIds.contains(thread.threadId)
            }
        }
    }

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                VStack {
                    // タブボタン
                    HStack {
                        Button(action: { selectedTab = .all }) {
                            Text("すべてのメッセージ")
                                .font(.subheadline)
                                .foregroundColor(selectedTab == .all ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == .all ? Color.teal : Color.clear)
                                .cornerRadius(8)
                        }

                        Button(action: { selectedTab = .unread }) {
                            Text("未読")
                                .font(.subheadline)
                                .foregroundColor(selectedTab == .unread ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == .unread ? Color.teal : Color.clear)
                                .cornerRadius(8)
                        }

                        Button(action: { selectedTab = .favorite }) {
                            Text("お気に入り")
                                .font(.subheadline)
                                .foregroundColor(selectedTab == .favorite ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == .favorite ? Color.teal : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    contentForSignedIn
                }
            } else {
                guestView
            }
        }
        .navigationTitle("DM一覧")
        .searchable(text: $searchText, prompt: "タイトル、ニックネームで検索")
        .onAppear {
            if authViewModel.isSignedIn && !isInitialFetchDone {
                dmViewModel.setAuthViewModel(authViewModel)
                fetchThreads()
                isInitialFetchDone = true
                loadFavorites()
            }
        }
        .refreshable {
            if authViewModel.isSignedIn {
                profileViewModel.userNicknames = [:]
                await fetchThreadsAsync()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                dmViewModel.setAuthViewModel(authViewModel)
                fetchThreads()
                loadFavorites()
            } else {
                dmViewModel.threads = []
                profileViewModel.userNicknames = [:]
                isInitialFetchDone = false
                favoriteThreadIds = []
            }
        }
    }

    // ★★★ 修正箇所1：ロジックを View の外（計算プロパティ）に移動 ★★★
    private var emptyListMessage: String {
        if !searchText.isEmpty {
            return "「\(searchText)」に一致するDMはありません。"
        }
        switch selectedTab {
        case .all:
            return "表示できるDMがありません。"
        case .unread:
            return "未読のDMがありません。"
        case .favorite:
            return "お気に入りのDMがありません。"
        }
    }

    private var contentForSignedIn: some View {
        Group {
            if dmViewModel.isLoading && dmViewModel.threads.isEmpty {
                ProgressView()
            } else if dmViewModel.threads.isEmpty {
                Text("DMがありません。")
                    .foregroundColor(.secondary)
            // ★★★ 修正箇所2： `else if` 内のロジックを `emptyListMessage` 呼び出しに置き換え ★★★
            } else if filteredThreads.isEmpty {
                Text(emptyListMessage)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                List(filteredThreads) { thread in
                    NavigationLink(
                        destination: ConversationView(thread: thread, viewModel: dmViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(profileViewModel)
                    ) {
                        DMListRowView(
                            thread: thread,
                            profileViewModel: profileViewModel,
                            isFavorite: favoriteThreadIds.contains(thread.threadId)
                        )
                        .environmentObject(authViewModel)
                    }
                    .contextMenu {
                        Button(action: {
                            toggleFavorite(threadId: thread.threadId)
                        }) {
                            if favoriteThreadIds.contains(thread.threadId) {
                                Label("お気に入りから削除", systemImage: "star.fill")
                            } else {
                                Label("お気に入りに移動", systemImage: "star")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    // ★★★ 修正ここまで ★★★

    private var guestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("DM機能を利用するにはログインが必要です。")
                .multilineTextAlignment(.center)
            Button("ログイン / 新規登録") {
                showAuthenticationSheet.wrappedValue = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func fetchThreads() {
        guard let userId = authViewModel.userSub else { return }
        Task {
            await dmViewModel.fetchThreads(userId: userId)
            if !dmViewModel.threads.isEmpty {
                await fetchAllNicknames(for: dmViewModel.threads)
            }
        }
    }

    private func fetchThreadsAsync() async {
        guard let userId = authViewModel.userSub else { return }
        await dmViewModel.fetchThreads(userId: userId)
        if !dmViewModel.threads.isEmpty {
            await fetchAllNicknames(for: dmViewModel.threads)
        }
    }

    private func fetchAllNicknames(for threads: [Thread]) async {
        guard let myUserId = authViewModel.userSub else { return }
        let opponentIds = Set(
            threads.flatMap { $0.participants }
                   .filter { $0 != myUserId }
        )
        for opponentId in opponentIds {
            if profileViewModel.userNicknames[opponentId] == nil {
                Task {
                    _ = await profileViewModel.fetchNickname(userId: opponentId)
                }
            }
        }
    }

    private func toggleFavorite(threadId: String) {
        if favoriteThreadIds.contains(threadId) {
            favoriteThreadIds.remove(threadId)
        } else {
            favoriteThreadIds.insert(threadId)
        }
        saveFavorites()
    }

    private func saveFavorites() {
        guard let userId = authViewModel.userSub else { return }
        let userFavoritesKey = "favorites_\(userId)"
        UserDefaults.standard.set(Array(favoriteThreadIds), forKey: userFavoritesKey)
        print("✅ お気に入りを保存: \(favoriteThreadIds.count)件")
    }

    private func loadFavorites() {
        guard let userId = authViewModel.userSub else { return }
        let userFavoritesKey = "favorites_\(userId)"
        let saved = UserDefaults.standard.array(forKey: userFavoritesKey) as? [String] ?? []
        favoriteThreadIds = Set(saved)
        print("✅ お気に入りを読み込み: \(favoriteThreadIds.count)件")
    }
}
