import SwiftUI
import Combine

struct DMListView: View {
    @StateObject private var dmViewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // ★ 追加: 課金管理
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var searchText = ""
    @State private var isInitialFetchDone = false
    
    @State private var selectedTab: DMTab = .all

    @State private var favoriteThreadIds: Set<String> = []
    
    // 削除されたスレッド + 削除時刻を記録
    @State private var deletedThreads: [String: Date] = [:]
    
    // 最後のメッセージとその日付をキャッシュ
    @State private var lastMessageCache: [String: (text: String, date: Date)] = [:]

    enum DMTab {
        case all
        case unread
        case favorite
    }

    private var filteredThreads: [DMThread] {
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

    private func applyTabFilter(_ threads: [DMThread], myUserId: String) -> [DMThread] {
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
        VStack(spacing: 0) {
            // ★★★ 追加: バナー広告 ★★★
            if !subscriptionManager.isPremium {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
            }
            
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
                profileViewModel.userProfileImages = [:]
                lastMessageCache = [:]
                await fetchThreadsAsync()
            }
        }
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            if authViewModel.isSignedIn {
                Task {
                    await fetchAllNicknames(for: dmViewModel.threads)
                }
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
                profileViewModel.userProfileImages = [:]
                isInitialFetchDone = false
                favoriteThreadIds = []
                deletedThreads = [:]
                lastMessageCache = [:]
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
                    // ★★★ 修正: ZStackを使って矢印(>)を消すテクニック ★★★
                    ZStack(alignment: .leading) {
                        // 1. 中身
                        DMListRowView(
                            thread: thread,
                            profileViewModel: profileViewModel,
                            isFavorite: favoriteThreadIds.contains(thread.threadId),
                            lastMessagePreview: lastMessageCache[thread.threadId]?.text
                        )
                        .environmentObject(authViewModel)
                        
                        // 2. 透明なリンク
                        NavigationLink(
                            destination: ConversationView(thread: thread, viewModel: dmViewModel)
                                .environmentObject(authViewModel)
                                .environmentObject(profileViewModel)
                        ) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    .contextMenu {
                        Button {
                            toggleFavorite(threadId: thread.threadId)
                        } label: {
                            if favoriteThreadIds.contains(thread.threadId) {
                                Label("お気に入りから削除", systemImage: "star.fill")
                            } else {
                                Label("お気に入りに移動", systemImage: "star")
                            }
                        }
                        
                        Button(role: .destructive) {
                            deleteThread(threadId: thread.threadId)
                        } label: {
                            Label("この会話を削除", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.plain)
                .task {
                    await fetchLastMessagesForThreads(filteredThreads)
                }
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
                await fetchLastMessagesForThreads(dmViewModel.threads)
            }
        }
    }

    private func fetchThreadsAsync() async {
        guard let userId = authViewModel.userSub else { return }
        await dmViewModel.fetchThreads(userId: userId)
        if !dmViewModel.threads.isEmpty {
            await fetchAllNicknames(for: dmViewModel.threads)
            await fetchLastMessagesForThreads(dmViewModel.threads)
        }
    }

    private func fetchAllNicknames(for threads: [DMThread]) async {
        guard let myUserId = authViewModel.userSub else { return }
        let opponentIds = Set(
            threads.flatMap { $0.participants }
                .filter { $0 != myUserId }
        )
        for opponentId in opponentIds {
            _ = await profileViewModel.fetchNicknameAndImage(userId: opponentId)
        }
    }
    
    private func fetchLastMessagesForThreads(_ threads: [DMThread]) async {
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("fetchLastMessages: トークン取得失敗")
            return
        }
        
        let threadsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/threads")!

        for thread in threads {
            if lastMessageCache[thread.threadId] != nil {
                continue
            }
          
            let url = threadsEndpoint
                .appendingPathComponent(thread.threadId)
                .appendingPathComponent("messages")
          
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue(idToken, forHTTPHeaderField: "Authorization")

                let (data, response) = try await URLSession.shared.data(for: request)
              
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    print("fetchLastMessages: サーバーエラー (threadId: \(thread.threadId))")
                    lastMessageCache[thread.threadId] = (text: "エラー", date: Date())
                    continue
                }

                let messages = try JSONDecoder().decode([Message].self, from: data)
              
                if let lastMessage = messages.last {
                    let preview = formatMessagePreview(lastMessage.text)
                    let date = parseDate(lastMessage.timestamp) ?? Date()
                    lastMessageCache[thread.threadId] = (text: preview, date: date)
                } else {
                    lastMessageCache[thread.threadId] = (text: "メッセージなし", date: Date())
                }
            } catch {
                print("fetchLastMessages: デコード失敗 (threadId: \(thread.threadId)) \(error)")
                lastMessageCache[thread.threadId] = (text: "エラー", date: Date())
            }
        }
    }
    
    private func formatMessagePreview(_ text: String) -> String {
        if text.contains("[image]") || text.contains("🖼️") {
            return "🖼️"
        }
        let maxLength = 30
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
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
        print("✅ スレッド '\(threadId)' を削除しました（削除時刻: \(Date())）")
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
        print("✅ 削除されたスレッドを保存: \(deletedThreads.count)件")
    }
    
    private func loadDeletedThreads() {
        guard let userId = authViewModel.userSub else { return }
        let userDeletedKey = "deleted_threads_\(userId)"
        if let encoded = UserDefaults.standard.dictionary(forKey: userDeletedKey) as? [String: Double] {
            deletedThreads = encoded.mapValues { Date(timeIntervalSince1970: $0) }
        }
        print("✅ 削除されたスレッドを読み込み: \(deletedThreads.count)件")
    }
}
