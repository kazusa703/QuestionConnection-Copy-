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
    
    // ★★★ 修正：削除されたスレッド + 削除時刻を記録 ★★★
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
        
        // ★★★ 修正：削除フィルタをより柔軟に ★★★
               let nonDeleted = nonBlocked.filter { thread in
                   // 削除されていない場合は表示
                   guard let deletedAt = deletedThreads[thread.threadId] else {
                       return true
                   }
                   
                   // 削除されている場合：削除時刻より後のメッセージがあれば再表示
                   if let threadUpdatedDate = parseDate(thread.lastUpdated),
                      threadUpdatedDate > deletedAt {
                       // 削除後に新しいメッセージが来たので再表示
                       print("✅ スレッド '\(thread.threadId)' は削除後に新しいメッセージがあるため再表示します（更新時刻: \(threadUpdatedDate)、削除時刻: \(deletedAt)）")
                       return true
                   }
                   
                   // ★★★ 追加：最後のメッセージが自分が送ったものならば再表示 ★★★
                   if let lastMessage = dmViewModel.messages.last,
                      let myUserId = authViewModel.userSub,
                      lastMessage.senderId == myUserId {
                       // 自分が送ったメッセージがあれば再表示
                       print("✅ スレッド '\(thread.threadId)' は自分が新しいメッセージを送ったため再表示します")
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
        // ★★★ 追加：画面が表示される度にスレッド一覧を更新 ★★★
               .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
                   if authViewModel.isSignedIn {
                       fetchThreads()
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

    // ★★★ 修正：削除時刻を記録 ★★★
    private func deleteThread(threadId: String) {
        deletedThreads[threadId] = Date()
        saveDeletedThreads()
        print("✅ スレッド '\(threadId)' を削除しました（削除時刻: \(Date())）")
    }
    
    private func markAsUnread(threadId: String) {
        guard let userId = authViewModel.userSub else { return }
        ThreadReadTracker.shared.markAsUnread(userId: userId, threadId: threadId)
        print("✅ スレッド '\(threadId)' を未読に戻しました")
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
    
    // ★★★ 修正：削除時刻も一緒に保存・読み込み ★★★
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
