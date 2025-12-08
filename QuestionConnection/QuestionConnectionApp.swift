import SwiftUI
import GoogleMobileAds

@main
struct QuestionConnectionApp: App {
    // 定義だけしておく（初期化は init で行う）
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var dmViewModel: DMViewModel
    @StateObject private var subscriptionManager: SubscriptionManager
    
    // ★★★ 追加: ナビゲーション管理 ★★★
    @StateObject private var navigationManager = NavigationManager()
    
    // アプリデリゲート（プッシュ通知用）を接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 1. AdMob初期化
        MobileAds.shared.start(completionHandler: nil)
        
        // 2. AuthViewModel を 1つだけ作る
        let auth = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: auth)
        
        // 3. 同じ auth インスタンスを ProfileViewModel に渡す
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: auth))
        
        // 4. DMViewModel を作成
        let dmVM = DMViewModel()
        dmVM.setAuthViewModel(auth) // AuthViewModelを設定
        _dmViewModel = StateObject(wrappedValue: dmVM)
        
        // 5. SubscriptionManager は依存がないのでここで初期化してもOK
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(dmViewModel)
                .environmentObject(subscriptionManager)
                .environmentObject(navigationManager) // ★ 追加
                .onAppear {
                    // アプリ起動時にバッジを消すなどの処理があればここ
                }
        }
    }
}
