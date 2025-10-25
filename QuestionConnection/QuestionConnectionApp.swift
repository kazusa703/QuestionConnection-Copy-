import SwiftUI

@main
struct QuestionConnectionApp: App {
    // --- ★★★ ここで共有ViewModelを作成 ★★★ ---
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var profileViewModel = ProfileViewModel() // ProfileViewModelもここで作成

    var body: some Scene {
        WindowGroup {
            ContentView()
                // --- ★★★ ここでViewModelを注入 ★★★ ---
                .environmentObject(authViewModel)    // AuthViewModelを注入
                .environmentObject(profileViewModel) // ProfileViewModelを注入
        }
    }
}
