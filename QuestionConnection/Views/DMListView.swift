import SwiftUI

struct DMListView: View {
    @StateObject private var dmViewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var searchText = ""
    @State private var isInitialFetchDone = false

    // ブロック除外 → 検索の順でフィルタリング
    private var filteredThreads: [Thread] {
        guard let myUserId = authViewModel.userSub else { return [] }

        // 1) ブロックしている相手のスレッドを除外
        let nonBlocked = dmViewModel.threads.filter { thread in
            let opponentId = thread.participants.first(where: { $0 != myUserId }) ?? ""
            return !profileViewModel.isBlocked(userId: opponentId)
        }

        // 2) 検索未入力ならそのまま返す
        guard !searchText.isEmpty else { return nonBlocked }

        // 3) タイトルまたは相手ニックネームで検索
        return nonBlocked.filter { thread in
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
    }

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                contentForSignedIn
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
            } else {
                dmViewModel.threads = []
                profileViewModel.userNicknames = [:]
                isInitialFetchDone = false
            }
        }
    }

    // ログイン時の内容
    private var contentForSignedIn: some View {
        Group {
            if dmViewModel.isLoading && dmViewModel.threads.isEmpty {
                ProgressView()
            } else if dmViewModel.threads.isEmpty {
                Text("DMがありません。")
                    .foregroundColor(.secondary)
            } else if filteredThreads.isEmpty {
                if searchText.isEmpty {
                    Text("表示できるDMがありません。")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("「\(searchText)」に一致するDMはありません。")
                        .foregroundColor(.secondary)
                        .padding()
                }
                Spacer()
            } else {
                List(filteredThreads) { thread in
                    NavigationLink(
                        destination: ConversationView(thread: thread, viewModel: dmViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(profileViewModel)
                    ) {
                        DMListRowView(thread: thread, profileViewModel: profileViewModel)
                            .environmentObject(authViewModel)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // ゲスト表示
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

    // 初回取得
    private func fetchThreads() {
        guard let userId = authViewModel.userSub else { return }
        Task {
            await dmViewModel.fetchThreads(userId: userId)
            if !dmViewModel.threads.isEmpty {
                await fetchAllNicknames(for: dmViewModel.threads)
            }
        }
    }

    // refreshable 用
    private func fetchThreadsAsync() async {
        guard let userId = authViewModel.userSub else { return }
        await dmViewModel.fetchThreads(userId: userId)
        if !dmViewModel.threads.isEmpty {
            await fetchAllNicknames(for: dmViewModel.threads)
        }
    }

    // 相手ニックネームをまとめて取得（ProfileViewModel 側で重複抑止する想定）
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
}
