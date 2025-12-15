import SwiftUI

/// ヘルプヒントボタン（2秒長押しでアラート表示）
struct HelpHintButton: View {
    let title: String
    let message: String
    
    @State private var showAlert = false
    @State private var isPressed = false
    
    var body: some View {
        Image(systemName: "info.circle")
            .font(.system(size: 18))
            .foregroundColor(. blue.opacity(0.8))
            .scaleEffect(isPressed ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 2.0,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {
                    // 2秒長押し完了時
                    let impactFeedback = UIImpactFeedbackGenerator(style:  .medium)
                    impactFeedback.impactOccurred()
                    showAlert = true
                }
            )
            .alert(title, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

// MARK: - Preview

#Preview {
    HelpHintButton(
        title: "質問一覧について",
        message: "ここでは他のユーザーが作成した問題を見ることができます。タップして挑戦してみましょう！"
    )
    .padding()
}
