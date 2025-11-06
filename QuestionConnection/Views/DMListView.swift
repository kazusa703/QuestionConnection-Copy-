import SwiftUI

struct DMListView: View {
    @StateObject private var viewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    // 共有された ProfileViewModel を受け取る
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    // ★★★ 1. 検索テキスト用のStateを追加 ★★★
    @State private var searchText = ""

    // ★★★ 2. 検索ロジック（算出プロパティ）を追加 ★★★
    private var filteredThreads: [Thread] {
        // 検索テキストが空なら、全スレッドを返す
        guard !searchText.isEmpty else {
            return viewModel.threads
        }
        
        // 自分のIDを取得
        guard let myUserId = authViewModel.userSub else {
            return viewModel.threads // 念のため
        }

        // 検索テキストでフィルタリング
        return viewModel.threads.filter { thread in
            // 1. 質問タイトルで検索
            if thread.questionTitle.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            // 2. 相手のニックネームで検索
            // 相手のIDを特定
            if let opponentId = thread.participants.first(where: { $0 != myUserId }) {
                // キャッシュからニックネームを取得
                if let nickname = profileViewModel.userNicknames[opponentId] {
                    if nickname.localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                }
            }
            
            // どちらにも一致しなければ除外
            return false
        }
    }

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                // --- ログイン済みユーザー向けの表示 ---
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.threads.isEmpty { // 元データが空かチェック
                    Text("DMがありません。")
                        .foregroundColor(.secondary)
                // ★★★ 3. 検索結果が空の場合の表示を追加 ★★★
                } else if filteredThreads.isEmpty {
                    Text("「\(searchText)」に一致するDMはありません。")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer() // 上に寄せる
                } else {
                    // ★★★ 4. viewModel.threads を filteredThreads に変更 ★★★
                    List(filteredThreads) { thread in
                        NavigationLink(destination: ConversationView(thread: thread)) {
                            // ニックネームを非同期で読み込む専用ビューを使用
                            DMListRowView(
                                thread: thread,
                                profileViewModel: profileViewModel // 共有VM を渡す
                            )
                            .environmentObject(authViewModel)
                        }
                    }
                }
            } else {
                // --- ゲストユーザー向けの表示 ---
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
        // ★★★ 5. .searchable モディファイアを追加 ★★★
        .searchable(text: $searchText, prompt: "タイトル、ニックネームで検索")
        .onAppear {
            if authViewModel.isSignedIn {
                // viewModelにauthViewModelをセット
                viewModel.setAuthViewModel(authViewModel)
                fetchThreads()
            }
        }
        .refreshable {
            if authViewModel.isSignedIn {
                // ★★★ 修正: ニックネームキャッシュをリセットする行を追加 ★★★
                profileViewModel.userNicknames = [:]
                await fetchThreadsAsync()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                // viewModelにauthViewModelをセット
                viewModel.setAuthViewModel(authViewModel)
                fetchThreads()
            } else {
                viewModel.threads = []
                profileViewModel.userNicknames = [:]
            }
        }
    }

    // スレッド一覧を取得するヘルパー関数
    private func fetchThreads() {
        guard let userId = authViewModel.userSub else { return }
        Task {
            await viewModel.fetchThreads(userId: userId)
            
            if !viewModel.threads.isEmpty {
                await fetchAllNicknames(for: viewModel.threads)
            }
        }
    }

    // refreshable 用の非同期ヘルパー関数
    private func fetchThreadsAsync() async {
        guard let userId = authViewModel.userSub else { return }
        
        await viewModel.fetchThreads(userId: userId)
        
        if !viewModel.threads.isEmpty {
            await fetchAllNicknames(for: viewModel.threads)
        }
    }
    
    /// 取得した全スレッドを調べ、ニックネームが未取得の相手がいたら取得する
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


