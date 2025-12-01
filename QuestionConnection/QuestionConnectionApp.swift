import SwiftUI
import GoogleMobileAds // AdMob

@main
struct QuestionConnectionApp: App {
    // 各マネージャーを初期化
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var profileViewModel: ProfileViewModel
    
    // 課金機能マネージャー
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    init() {
        // ★ AdMobの初期化 (最新の書き方に修正) ★
        // completionHandler: nil を明示的に書かず、クロージャを省略するか
        // 型推論を助ける書き方に変更します。
        MobileAds.shared.start(completionHandler: nil)
        
        // 既存の初期化処理
        let auth = AuthViewModel()
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: auth))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(subscriptionManager) // 全画面で課金状態を共有
        }
    }
}
