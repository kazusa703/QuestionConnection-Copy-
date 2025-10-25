import SwiftUI

struct DMListView: View {
    @StateObject private var viewModel = DMViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    // 共有された ProfileViewModel を受け取る
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                // --- ログイン済みユーザー向けの表示 ---
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.threads.isEmpty {
                    Text("DMがありません。")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.threads) { thread in
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
                // --- ★★★ ここを修正しました (プレースホルダーを元に戻した) ★★★ ---
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
                // --- ★★★ ここまで ★★★ ---
            }
        }
        .navigationTitle("DM一覧")
        .onAppear {
            if authViewModel.isSignedIn {
                fetchThreads()
            }
        }
        .refreshable {
            if authViewModel.isSignedIn {
                await fetchThreadsAsync()
            }
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                fetchThreads()
            } else {
                viewModel.threads = []
                profileViewModel.userNicknames = [:]
            }
        }
    }

    // スレッド一覧を取得するヘルパー関数
    private func fetchThreads() {
         guard let userId = authViewModel.userSub, let idToken = authViewModel.idToken else { return }
         Task {
             // 1. スレッド一覧を非同期で取得
             await viewModel.fetchThreads(userId: userId, idToken: idToken)
             
             // 2. 取得が成功したら、ニックネームの取得をトリガー
             if !viewModel.threads.isEmpty {
                 await fetchAllNicknames(for: viewModel.threads)
             }
         }
    }

    // refreshable 用の非同期ヘルパー関数
    private func fetchThreadsAsync() async {
         guard let userId = authViewModel.userSub, let idToken = authViewModel.idToken else { return }
         
         // 1. スレッド一覧を非同期で取得
         await viewModel.fetchThreads(userId: userId, idToken: idToken)
         
         // 2. 取得が成功したら、ニックネームの取得をトリガー
         if !viewModel.threads.isEmpty {
             await fetchAllNicknames(for: viewModel.threads)
         }
    }
    
    /// 取得した全スレッドを調べ、ニックネームが未取得の相手がいたら取得する
    private func fetchAllNicknames(for threads: [Thread]) async {
        guard let myUserId = authViewModel.userSub,
              let idToken = authViewModel.idToken else { return }
        
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
                    _ = await profileViewModel.fetchNickname(userId: opponentId, idToken: idToken)
                }
            }
        }
    }
}
