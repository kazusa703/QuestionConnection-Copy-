import SwiftUI

struct MainTabView: View {
    // 認証状態を共有
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // ★ 修正: DMViewModelに引数なしのinitを使用し、onAppearで注入する
    @StateObject private var dmViewModel = DMViewModel()
    
    // タブの選択状態
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            // 1. 質問一覧タブ
            NavigationView {
                ContentView()
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle.portrait")
                Text("質問")
            }
            .tag(0)
            
            // 2. 検索/作成タブ (例)
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
        .environmentObject(dmViewModel) // 下層ビューに提供
        .onAppear {
            // ★ 修正: 画面表示時に依存関係を注入
            dmViewModel.setAuthViewModel(authViewModel)
        }
    }
}
