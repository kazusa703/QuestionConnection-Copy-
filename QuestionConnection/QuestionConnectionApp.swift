import SwiftUI
import UserNotifications // ★★★ 1. 通知フレームワークをインポート ★★★

// ★★★ 2. AppDelegateクラスを追加 ★★★
// (プッシュ通知の許可、トークン取得などの "アプリ全体" のイベントを扱うため)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // アプリ起動完了時に呼ばれる
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 通知センターのデリゲート（通知をフォアグラウンドで受け取るためなど）を自分自身に設定
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // --- プッシュ通知のコア処理 ---
    
    /// 1. APNs (Apple Push Notification service) に登録が成功し、デバイストークンが返された時に呼ばれる
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Data型を16進数の文字列に変換 ( "abc123def456..." のような形式 )
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ [AppDelegate] APNsデバイストークン取得成功: \(tokenString)")
        
        // ★★★ 取得したトークンをサーバーに送信するタスクをスケジュール ★★★
        // (この時点では ViewModel がまだ準備できていない可能性があるため、NotificationCenter を使って通知する)
        NotificationCenter.default.post(name: .didReceiveDeviceToken, object: tokenString)
    }

    /// 2. APNsへの登録が失敗した時に呼ばれる
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] APNsデバイストークン取得失敗: \(error.localizedDescription)")
    }
    
    /// 3. アプリがフォアグラウンド（起動中）の時に通知を受け取った時の処理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // バナー、サウンド、バッジを表示する設定
        completionHandler([.banner, .sound, .badge])
    }
}

// ★★★ 3. デバイストークンを渡すためのカスタム通知名 ★★★
extension Notification.Name {
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
}


@main
struct QuestionConnectionApp: App {
    // --- ★★★ 4. AppDelegate を SwiftUI アプリに接続 ★★★ ---
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var profileViewModel: ProfileViewModel

    init() {
        let authVM = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: authVM)
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authVM))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
                // ★★★ 5. デバイストークンを受け取ったら、ViewModel に渡す ★★★
                .onReceive(NotificationCenter.default.publisher(for: .didReceiveDeviceToken)) { notification in
                    if let tokenString = notification.object as? String {
                        // ログイン状態を確認してから送信タスクを実行
                        if authViewModel.isSignedIn {
                            Task {
                                await profileViewModel.registerDeviceToken(deviceTokenString: tokenString)
                            }
                        } else {
                            print("デバイストークン受信: 未ログインのためサーバー登録は保留")
                        }
                    }
                }
                // ★★★ 6. ログイン状態が変化した時にもトークン登録を試みる ★★★
                .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
                    if isSignedIn {
                        // ログインに成功したら、通知許可を求める
                        registerForPushNotifications()
                    }
                }
        }
    }
    
    // ★★★ 7. 通知許可を求める関数 ★★★
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if let error = error {
                print("❌ 通知許可リクエストエラー: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("✅ 通知許可OK")
                // 許可されたら、メインスレッドで APNs に登録を試みる
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ 通知が拒否されました")
            }
        }
    }
}
