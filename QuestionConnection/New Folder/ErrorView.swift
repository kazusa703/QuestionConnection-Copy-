import SwiftUI

/// エラー表示用のView
struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    
    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // アイコン
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(. gray)
            
            // エラーメッセージ
            Text(error.localizedDescription)
                .font(. headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // 回復方法
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // リトライボタン
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再試行")
                    }
                    .padding(. horizontal, 24)
                    .padding(.vertical, 12)
                    . background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
    }
}

/// オフライン時のバナー表示
struct OfflineBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            Text("オフラインです")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(. vertical, 8)
        .background(Color.red.opacity(0.9))
    }
}

/// ローディング表示
struct LoadingView: View {
    var message: String = "読み込み中..."
    
    var body: some View {
        VStack(spacing:  16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(. systemBackground).opacity(0.8))
    }
}

/// 空の状態表示
struct EmptyStateView:  View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?  = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(. gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(. primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        . padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        . background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(error: . networkError) {
        print("Retry tapped")
    }
}

#Preview("Offline Banner") {
    VStack {
        OfflineBanner()
        Spacer()
    }
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "questionmark.circle",
        title: "質問がありません",
        message: "まだ質問が投稿されていません",
        actionTitle: "質問を作成"
    ) {
        print("Action tapped")
    }
}
