import SwiftUI

struct MainTabView: View {
    // 認証状態を共有
    @EnvironmentObject var authViewModel: AuthViewModel
    // DMのビューモデルもここで共有しておくと良い
    @StateObject private var dmViewModel = DMViewModel(authViewModel: AuthViewModel()) // 仮初期化、onAppearで注入推奨だが、EnvironmentObjectならMainAppで注入済みのはず
    // ※ 注意: MainAppですでに注入されている場合は @EnvironmentObject を使うべきですが、
    // ここではエラー回避のため安全策をとります。もしMainAppで .environmentObject(dmViewModel) しているなら
    // @EnvironmentObject var dmViewModel: DMViewModel に変えてください。
    
    // タブの選択状態
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            // 1. 質問一覧タブ
            NavigationView {
                // ここは既存の質問一覧ビュー (ContentViewなど)
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
            // ★★★ ここを修正: 必要な引数を渡す ★★★
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
        // DMViewModelを環境変数として注入（下層ビューで使うため）
        // もしAppファイルで注入済みなら不要だが、念のため。
        // ただし dmViewModel の初期化に authViewModel が必要なら注意。
    }
}
