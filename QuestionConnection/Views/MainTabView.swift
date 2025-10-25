import SwiftUI

struct MainTabView: View {
    // ★★★ 追加: 環境から profileViewModel を受け取る ★★★
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    var body: some View {
        TabView {
            BoardView()
                .tabItem {
                    Label("掲示板", systemImage: "list.bullet.rectangle")
                }

            CreateQuestionView()
                .tabItem {
                    Label("質問作成", systemImage: "plus.square")
                }

            DMListView()
                .tabItem {
                    Label("DM", systemImage: "message")
                }
                // ★★★ 追加: DMタブにVMを渡す ★★★
                .environmentObject(profileViewModel)

            ProfileView()
                .tabItem {
                    Label("プロフィール", systemImage: "person.crop.circle")
                }
                // ★★★ 追加: ProfileタブにVMを渡す ★★★
                .environmentObject(profileViewModel)
        }
    }
}
