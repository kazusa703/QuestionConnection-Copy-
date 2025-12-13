import SwiftUI

struct QuizCompleteView: View {
    let question: Question
    let hasEssay: Bool
    @EnvironmentObject private var authViewModel:  AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    var onClose: (() -> Void)? = nil
    var onDMTap: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 20) {
            if hasEssay {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("回答完了。")
                        .font(.headline)
                    Text("作成者が記述式を採点中...  ⏳")
                        . font(.subheadline)
                        . foregroundColor(.secondary)
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
                if let message = question.dmInviteMessage, !message.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope. fill")
                                .foregroundColor(.blue)
                            Text("出題者からのメッセージ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(message)
                            . font(.body)
                            . foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            Spacer()
            if hasEssay {
                Button(action: {
                    if let action = onClose {
                        action()
                    } else {
                        navManager.popToRoot(tab: 3)
                        navManager.tabSelection = 3
                        dismiss()
                    }
                }) {
                    Text("プロフィールへ")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        . foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                Button(action: {
                    if let action = onDMTap {
                        action()
                    } else {
                        navManager.popToRoot(tab: 2)
                        navManager.tabSelection = 2
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("DMへ")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Button(action: {
                    if let action = onClose {
                        action()
                    } else {
                        navManager.popToRoot(tab: 0)
                        navManager.tabSelection = 0
                        dismiss()
                    }
                }) {
                    Text("掲示板に戻る")
                        . frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .presentationDetents([hasEssay ? .fraction(0.4) : .fraction(0.55)])
    }
}
