import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject var navManager: NavigationManager
    
    // ★★★ 追加: ネットワーク監視 ★★★
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // 既存のタブビュー
            TabView(selection: $navManager.tabSelection) {
                // 1. 質問一覧タブ
                NavigationStack(path: $navManager.questionPath) {
                    BoardView()
                }
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("掲示板")
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
            
            // ★★★ オフラインバナー ★★★
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: networkMonitor.isConnected)
                    .zIndex(1) // 最前面に表示
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    let dmVM = DMViewModel()
    let navManager = NavigationManager()
    dmVM.setAuthViewModel(authVM)
    
    return MainTabView()
        .environmentObject(authVM)
        .environmentObject(dmVM)
        .environmentObject(navManager)
}
