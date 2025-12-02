import SwiftUI
import GoogleMobileAds

// ★ 本番用IDを設定しました
struct AdMobConfig {
    // バナー広告ID
    static let bannerID = "ca-app-pub-9569882864362674/2243703735"
    // 全画面広告ID
    static let interstitialID = "ca-app-pub-9569882864362674/4869867071"
}

// バナー広告View
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobConfig.bannerID
        
        // RootViewControllerを取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// 全画面広告マネージャー
class InterstitialAdManager: NSObject {
    var interstitial: InterstitialAd?
    
    // 広告をロードしておく
    func loadAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobConfig.interstitialID,
                            request: request) { [weak self] ad, error in
            if let error = error {
                print("広告読み込み失敗: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
        }
    }
    
    // 広告を表示する
    func showAd(completion: @escaping () -> Void) {
        guard let interstitial = interstitial,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("広告の準備ができていません")
            completion()
            return
        }
        
        interstitial.present(from: rootVC)
        
        // 次回のためにロードし直す
        self.interstitial = nil
        self.loadAd()
        completion()
    }
}
