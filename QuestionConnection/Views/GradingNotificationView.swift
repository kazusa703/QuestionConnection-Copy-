import SwiftUI

struct GradingNotificationView: View {
    @Binding var isPresented: Bool
    let onSendMessage: () -> Void
    let onLater: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 成功アイコン
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("正解にしました")
                    .font(. title)
                    .fontWeight(.bold)
                
                Text("回答者と会話を始めましょう！")
                    .font(.subheadline)
                    . foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
            
            Spacer()
            
            // アクションボタン
            VStack(spacing: 12) {
                Button(action: onSendMessage) {
                    HStack {
                        Image(systemName: "envelope. fill")
                        Text("メッセージを送る")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: onLater) {
                    Text("あとで")
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .presentationDetents([.fraction(0.55)])
    }
}

#Preview {
    GradingNotificationView(
        isPresented: .constant(true),
        onSendMessage: { print("Send message") },
        onLater: { print("Later") }
    )
}
