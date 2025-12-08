import SwiftUI

struct QuizCompleteView: View {
    let question: Question
    let hasEssay: Bool
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    
    // ★★★ 追加: 閉じるボタンのアクションを外部から注入可能にする ★★★
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            if hasEssay {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("回答完了。")
                        .font(.headline)
                    
                    Text("作成者が記述式を採点中...   ⏳")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("おめでとうございます！")
                        .font(.headline)
                    
                    Text("全問正解です！")
                        .font(.headline)
                }
                .padding(20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // ★★★ 修正: onCloseがあればそれを実行、なければdismiss ★★★
            Button(action: {
                if let action = onClose {
                    action()
                } else {
                    dismiss()
                }
            }) {
                Text(hasEssay ? "プロフィールへ" : "掲示板に戻る") // 文言も少し調整
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.4)])
    }
}
