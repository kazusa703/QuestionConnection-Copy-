import SwiftUI
import Combine // ★★★ これを追加しました ★★★

// アプリ全体の画面遷移とタブ選択を管理するクラス
class NavigationManager: ObservableObject {
    // 現在選択されているタブ
    @Published var tabSelection: Int = 0
    
    // 各タブのナビゲーションパス（画面の積み重ね履歴）
    @Published var questionPath = NavigationPath()
    @Published var createPath = NavigationPath()
    @Published var dmPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    
    // 指定したタブのルート（最初の画面）に戻る
    func popToRoot(tab: Int) {
        switch tab {
        case 0: questionPath = NavigationPath()
        case 1: createPath = NavigationPath()
        case 2: dmPath = NavigationPath()
        case 3: profilePath = NavigationPath()
        default: break
        }
    }
}
