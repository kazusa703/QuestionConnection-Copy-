import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    // アプリ起動完了時
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // プッシュ通知の委譲設定
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }
    
    // デバイストークン取得成功時
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // トークンを文字列に変換 (例: 1a2b3c...)
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📲 Device Token: \(token)")
        
        // UserDefaultsに保存し、ログイン後に ProfileViewModel で送信させる
        UserDefaults.standard.set(token, forKey: "pendingDeviceToken")
    }
    
    // デバイストークン取得失敗時
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}

// 通知を受け取った時の動作設定
extension AppDelegate: UNUserNotificationCenterDelegate {
    // アプリがフォアグラウンド（開いている時）に通知が来た場合
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // バナーと音で通知する
        completionHandler([.banner, .sound, .badge])
    }
    
    // 通知をタップした時
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // 例: 特定の画面に遷移させるロジックをここに書く
        // 今回はログ出力のみ
        print("通知タップ: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}
