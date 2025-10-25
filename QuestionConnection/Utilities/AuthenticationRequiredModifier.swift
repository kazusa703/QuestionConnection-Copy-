import SwiftUI

// 認証が必要なビューに適用するViewModifier
struct AuthenticationRequiredModifier: ViewModifier {
    // AuthViewModelとログインシート表示フラグを環境から取得
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    func body(content: Content) -> some View {
        // contentは、このModifierが適用されるビュー（例: Button）
        content
            .onTapGesture { // タップされた時の処理を追加
                if authViewModel.isSignedIn {
                    // ログイン済みなら何もしない（元のビューのアクションが実行される）
                } else {
                    // 未ログインならログインシートを表示するフラグを立てる
                    showAuthenticationSheet.wrappedValue = true
                }
            }
    }
}

// Viewに .authenticationRequired() という形で簡単に適用できるようにするための拡張
extension View {
    func authenticationRequired() -> some View {
        modifier(AuthenticationRequiredModifier())
    }
}
