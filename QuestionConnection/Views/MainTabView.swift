import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject var navManager: NavigationManager
    
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $navManager.tabSelection) {
                // 1. 質問一覧タブ
                NavigationStack(path: $navManager.questionPath) {
                    BoardView()
                }
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("質問")
                }
                .tag(0)
                
                // 2. 検索/作成タブ
                NavigationStack(path: $navManager.createPath) {
                    CreateQuestionView()
                }
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("作成")
                }
                .tag(1)
                
                // 3. DM一覧タブ
                NavigationStack(path: $navManager.dmPath) {
                    DMListView()
                }
                .tabItem {
                    Image(systemName: "envelope")
                    Text("DM")
                }
                .tag(2)
                
                // 4. プロフィールタブ
                NavigationStack(path: $navManager.profilePath) {
                    ProfileView(
                        userId: authViewModel.userSub ?? "",
                        isMyProfile: true
                    )
                }
                .tabItem {
                    Image(systemName: "person")
                    Text("プロフィール")
                }
                .tag(3)
            }
            
            // オフラインバナー
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: networkMonitor.isConnected)
                    .zIndex(1)
            }
        }
        .onAppear {
            print("🟢 [MainTabView] 画面が表示されました")
        }
        // MainTabView.swift の onReceive 部分を修正

        // ★★★ 修正: note を受け取るように変更 ★★★
        . onReceive(NotificationCenter.default.publisher(for: .forcePopToBoard)) { note in
            print("🟢 [MainTabView] forcePopToBoard 通知を受信しました")
            print("🟢 [MainTabView] 現在のタブ:  \(navManager.tabSelection)")
            print("🟢 [MainTabView] questionPath. count: \(navManager.questionPath.count)")
            
            // 全てのナビゲーションパスをリセット
            navManager.questionPath = NavigationPath()
            navManager.createPath = NavigationPath()
            navManager.dmPath = NavigationPath()
            navManager.profilePath = NavigationPath()
            print("🟢 [MainTabView] 全てのNavigationPathをリセットしました")
            
            // 掲示板タブに移動
            navManager.tabSelection = 0
            print("🟢 [MainTabView] tabSelection を 0 に設定しました")
            
            // ★★★ 修正:  questionId を取得して渡す ★★★
            let questionId = note.object as?  String
            
            // 掲示板を再フェッチ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🟢 [MainTabView] boardShouldRefresh 通知を送信します questionId=\(questionId ??  "nil")")
                NotificationCenter.default.post(name: .boardShouldRefresh, object: questionId)
                print("🟢 [MainTabView] boardShouldRefresh 通知を送信しました")
            }
        }
    }
}
