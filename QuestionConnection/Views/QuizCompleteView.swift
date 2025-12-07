import SwiftUI

struct QuizCompleteView: View {
    let question: Question
    let hasEssay: Bool
    var onClose: () -> Void
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var navigateToInitialDM = false
    
    var body: some View {
        VStack(spacing: 20) {
            if hasEssay {
                // 記述式あり：採点待ち表示
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("回答完了")
                        .font(.headline)
                    
                    Text("作成者が記述式を採点中... ⏳")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                // 記述式なし：全問正解表示
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
                
                if let inviteMessage = question.dmInviteMessage, !inviteMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出題者からのメッセージ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(inviteMessage)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            if hasEssay {
                Button(action: {
                    dismiss()
                    onClose()
                }) {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                Button(action: { navigateToInitialDM = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("作成者にメッセージを送る")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    dismiss()
                    onClose()
                }) {
                    Text("あとで")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.5)])
        .sheet(isPresented: $navigateToInitialDM) {
            NavigationStack {
                InitialDMView(
                    recipientId: question.authorId,
                    questionTitle: question.title
                )
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
            }
        }
    }
}
