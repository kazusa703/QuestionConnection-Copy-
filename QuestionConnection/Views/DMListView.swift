import SwiftUI
import Combine

struct DMListView: View {
    @StateObject private var dmViewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var searchText = ""
    @State private var isInitialFetchDone = false
    
    @State private var selectedTab: DMTab = .all

    @State private var favoriteThreadIds: Set<String> = []
    
    @State private var deletedThreads: [String: Date] = [:]

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
        
        let nonDeleted = nonBlocked.filter { thread in
            guard let deletedAt = deletedThreads[thread.threadId] else {
                return true
            }
            
            if let threadUpdatedDate = parseDate(thread.lastUpdated),
               threadUpdatedDate > deletedAt {
                // ★★★ 修正：不要なログを削除（コスト削減） ★★★
                // print("✅ スレッド '\(thread.threadId)' は削除後に新しいメッセージがあるため再表示します（更新時刻: \(threadUpdatedDate)、削除時刻: \(deletedAt)）")
                return true
            }
            
            return false
        }

        guard !searchText.isEmpty else {
            return applyTabFilter(nonDeleted, myUserId: myUserId)
        }

        let searched = nonDeleted.filter { thread in
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

    private func parseDate(_ isoString: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: isoString) { return d }
        
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: isoString)
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
                loadDeletedThreads()
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
                loadDeletedThreads()
            } else {
                dmViewModel.threads = []
                profileViewModel.userNicknames = [:]
                isInitialFetchDone = false
                favoriteThreadIds = []
                deletedThreads = [:]
            }
        }
    }

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
                        // ★★★ 修正：名前だけを表示 ★★★
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
                        
                        Button(role: .destructive, action: {
                            deleteThread(threadId: thread.threadId)
                        }) {
                            Label("この会話を削除", systemImage: "trash")
                        }
                        
                        Button(action: {
                            markAsUnread(threadId: thread.threadId)
                        }) {
                            Label("未読に戻す", systemImage: "envelope.badge")
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

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

    private func deleteThread(threadId: String) {
        deletedThreads[threadId] = Date()
        saveDeletedThreads()
        // ★★★ 修正：削除操作の詳細ログを削除（コスト削減） ★★★
        // print("✅ スレッド '\(threadId)' を削除しました（削除時刻: \(Date())）")
    }
    
    private func markAsUnread(threadId: String) {
        guard let userId = authViewModel.userSub else { return }
        ThreadReadTracker.shared.markAsUnread(userId: userId, threadId: threadId)
        // ★★★ 修正：未読戻す操作の詳細ログを削除（コスト削減） ★★★
        // print("✅ スレッド '\(threadId)' を未読に戻しました")
    }

    private func saveFavorites() {
        guard let userId = authViewModel.userSub else { return }
        let userFavoritesKey = "favorites_\(userId)"
        UserDefaults.standard.set(Array(favoriteThreadIds), forKey: userFavoritesKey)
    }

    private func loadFavorites() {
        guard let userId = authViewModel.userSub else { return }
        let userFavoritesKey = "favorites_\(userId)"
        let saved = UserDefaults.standard.array(forKey: userFavoritesKey) as? [String] ?? []
        favoriteThreadIds = Set(saved)
    }
    
    private func saveDeletedThreads() {
        guard let userId = authViewModel.userSub else { return }
        let userDeletedKey = "deleted_threads_\(userId)"
        let encoded = deletedThreads.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(encoded, forKey: userDeletedKey)
        // ★★★ 修正：削除スレッド保存の詳細ログを削除（コスト削減） ★★★
        // print("✅ 削除されたスレッドを保存: \(deletedThreads.count)件")
    }
    
    private func loadDeletedThreads() {
        guard let userId = authViewModel.userSub else { return }
        let userDeletedKey = "deleted_threads_\(userId)"
        if let encoded = UserDefaults.standard.dictionary(forKey: userDeletedKey) as? [String: Double] {
            deletedThreads = encoded.mapValues { Date(timeIntervalSince1970: $0) }
        }
        // ★★★ 修正：削除スレッド読み込みの詳細ログを削除（コスト削減） ★★★
        // print("✅ 削除されたスレッドを読み込み: \(deletedThreads.count)件")
    }
}
