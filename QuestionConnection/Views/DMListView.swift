import SwiftUI

struct DMListView: View {
    // 1回目のコードの `viewModel` から `dmViewModel` に名前を合わせます
    @StateObject private var dmViewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    // 共有された ProfileViewModel を受け取る (両方のコードで共通)
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    // ★ 1. 検索テキスト用のState (1回目のコードから)
    @State private var searchText = ""

    // ★ 2. 検索 + ブロックフィルタリングロジック (1回目と2回目を統合)
    private var filteredThreads: [Thread] {
        guard let myUserId = authViewModel.userSub else { return [] }

        // 1. ブロックしているユーザーのスレッドを除外 (2回目のコードのロジック)
        let nonBlockedThreads = dmViewModel.threads.filter { thread in
            let opponentId = thread.participants.first(where: { $0 != myUserId }) ?? ""
            // 相手がブロックリストに含まれて *いない* スレッドのみ
            return !profileViewModel.isBlocked(userId: opponentId)
        }
    
        // 2. 検索テキストが空なら、ブロック除外済みの全スレッドを返す (1回目のコードのロジック)
        guard !searchText.isEmpty else {
            return nonBlockedThreads
        }

        // 3. 検索テキストでフィルタリング (1回目のコードのロジック)
        return nonBlockedThreads.filter { thread in
            // 3a. 質問タイトルで検索
            if thread.questionTitle.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            // 3b. 相手のニックネームで検索
            if let opponentId = thread.participants.first(where: { $0 != myUserId }) {
                if let nickname = profileViewModel.userNicknames[opponentId] {
                    if nickname.localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                }
            }
            
            return false
        }
    }

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                // --- ログイン済みユーザー向けの表示 ---
                
                // ★ 1回目のコードの分岐ロジックを採用
                if dmViewModel.isLoading {
                    ProgressView()
                } else if dmViewModel.threads.isEmpty { // 元データが空かチェック
                    Text("DMがありません。")
                        .foregroundColor(.secondary)
                // ★ 3. 検索結果 + ブロック結果が空の場合の表示
                } else if filteredThreads.isEmpty {
                    // 検索中かどうかでメッセージを分ける
                    if searchText.isEmpty {
                        Text("表示できるDMがありません。") // ブロックしているDMのみだった場合
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text("「\(searchText)」に一致するDMはありません。")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    Spacer() // 上に寄せる
                } else {
                    // ★ 4. filteredThreads を使用
                    List(filteredThreads) { thread in
                        // ★ 1回目のコードの NavigationLink(destination:) を採用
                        // (ConversationView に authViewModel を渡すため)
                        NavigationLink(destination: ConversationView(thread: thread)) {
                            DMListRowView(
                                thread: thread,
                                profileViewModel: profileViewModel // 共有VM を渡す
                            )
                            .environmentObject(authViewModel)
                        }
                    }
                }
            } else {
                // --- ゲストユーザー向けの表示 (1回目と同じ) ---
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
        }
        .navigationTitle("DM一覧")
        // ★ 5. .searchable (1回目と同じ)
        .searchable(text: $searchText, prompt: "タイトル、ニックネームで検索")
        .onAppear {
            if authViewModel.isSignedIn {
                // dmViewModelにauthViewModelをセット
                dmViewModel.setAuthViewModel(authViewModel)
                fetchThreads()
            }
        }
        .refreshable {
            if authViewModel.isSignedIn {
                // ★ ニックネームキャッシュをリセット (1回目と同じ)
                profileViewModel.userNicknames = [:]
                await fetchThreadsAsync()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                // dmViewModelにauthViewModelをセット
                dmViewModel.setAuthViewModel(authViewModel)
                fetchThreads()
            } else {
                // ★ 2回目のコードの clearThreads() の代わり
                dmViewModel.threads = []
                profileViewModel.userNicknames = [:]
            }
        }
    }

    // スレッド一覧を取得するヘルパー関数 (1回目と同じ)
    private func fetchThreads() {
        guard let userId = authViewModel.userSub else { return }
        Task {
            // DMViewModelからスレッド一覧を取得
            await dmViewModel.fetchThreads(userId: userId)
            
            // スレッド一覧が取得できたら、ニックネーム取得処理に進む
            if !dmViewModel.threads.isEmpty {
                await fetchAllNicknames(for: dmViewModel.threads)
            }
        }
    }

    // refreshable 用の非同期ヘルパー関数 (1回目と同じ)
    private func fetchThreadsAsync() async {
        guard let userId = authViewModel.userSub else { return }
        
        await dmViewModel.fetchThreads(userId: userId)
        
        if !dmViewModel.threads.isEmpty {
            await fetchAllNicknames(for: dmViewModel.threads)
        }
    }
    
    /// 取得した全スレッドを調べ、ニックネームが未取得の相手がいたら取得する (1回目と同じ)
    private func fetchAllNicknames(for threads: [Thread]) async {
        guard let myUserId = authViewModel.userSub else { return }
        
        // 1. 相手のIDだけをSet（重複なしのコレクション）にまとめる
        let opponentIds = Set(
            threads.flatMap { $0.participants }
                   .filter { $0 != myUserId }
        )
        
        // 2. 相手のIDリストをループ
        for opponentId in opponentIds {
            // 3. まだキャッシュにないIDだけをAPIで取得する
            if profileViewModel.userNicknames[opponentId] == nil {
                // （結果は待たずに）非同期でニックネーム取得を開始
                Task {
                    _ = await profileViewModel.fetchNickname(userId: opponentId)
                }
            }
        }
    }
}
