import SwiftUI

struct MainTabView: View {
    // 認証状態を共有
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // ★ 修正: 親から注入されたDMViewModelを使用
    @EnvironmentObject var dmViewModel: DMViewModel
    
    // タブの選択状態
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            // 1. 質問一覧タブ - ★ 修正: ContentViewではなくBoardViewを使用
            NavigationView {
                BoardView()
            }
            . tabItem {
                Image(systemName: "list.bullet.rectangle.portrait")
                Text("質問")
            }
            . tag(0)
            
            // 2. 検索/作成タブ
            NavigationView {
                CreateQuestionView()
            }
            .tabItem {
                Image(systemName: "plus.circle")
                Text("作成")
            }
            .tag(1)
            
            // 3. DM一覧タブ
            NavigationView {
                DMListView()
            }
            .tabItem {
                Image(systemName: "envelope")
                Text("DM")
            }
            .tag(2)
            
            // 4. プロフィールタブ
            NavigationView {
                ProfileView(
                    userId: authViewModel.userSub ?? "",
                    isMyProfile: true,
                    authViewModel: authViewModel
                )
            }
            .tabItem {
                Image(systemName: "person")
                Text("プロフィール")
            }
            .tag(3)
        }
    }
}
