import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    
    // ★★★ 修正: NavigationManagerを使用 ★★★
    @EnvironmentObject var navManager: NavigationManager
    
    var body: some View {
        // selection と path を navManager にバインディング
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
                    userId: authViewModel.userSub ??  "",
                    isMyProfile: true
                    // ★★★ authViewModel 引数を削除 ★★★
                )
            }
            . tabItem {
                Image(systemName: "person")
                Text("プロフィール")
            }
            . tag(3)

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
