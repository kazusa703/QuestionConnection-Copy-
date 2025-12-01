import SwiftUI
import GoogleMobileAds

// ※ テスト用IDです。本番リリース時には実際のIDに書き換えてください。
struct AdMobConfig {
    // テスト用バナーID
    static let bannerID = "ca-app-pub-3940256099942544/2934735716"
    // テスト用インタースティシャルID
    static let interstitialID = "ca-app-pub-3940256099942544/4411468910"
}

// バナー広告View
struct AdBannerView: UIViewRepresentable {
    // ★ GADBannerView -> BannerView に変更
    func makeUIView(context: Context) -> BannerView {
        // ★ GADAdSizeBanner -> AdSizeBanner に変更
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobConfig.bannerID
        
        // RootViewControllerを取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootVC
        }
        
        // ★ GADRequest -> Request に変更
        banner.load(Request())
        return banner
    }

    // ★ GADBannerView -> BannerView に変更
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// 全画面広告マネージャー
class InterstitialAdManager: NSObject {
    // ★ GADInterstitialAd -> InterstitialAd に変更
    var interstitial: InterstitialAd?
    
    // 広告をロードしておく
    func loadAd() {
        // ★ GADRequest -> Request に変更
        let request = Request()
        
        // ★ GADInterstitialAd -> InterstitialAd
        // ★ 引数名変更: withAdUnitID -> with
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
            completion() // 準備できてなければそのまま進む
            return
        }
        
        // ★ 引数名変更: fromRootViewController -> from
        interstitial.present(from: rootVC)
        
        // 次回のためにロードし直す
        self.interstitial = nil
        self.loadAd()
        completion()
    }
}
