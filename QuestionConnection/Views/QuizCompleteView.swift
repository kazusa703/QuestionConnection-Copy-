import SwiftUI

struct QuizCompleteView: View {
    let question: Question
    let hasEssay: Bool
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    var onClose: (() -> Void)? = nil
    var onDMTap: (() -> Void)? = nil

    @State private var showDMGuide = false

    // 共通ハンドラ
    private func handleBackToBoard() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            navManager.popToRoot(tab: 0)
            navManager.tabSelection = 0
            // 解答した questionId を通知に載せる
            NotificationCenter.default.post(name: .boardShouldRefresh, object: question.questionId)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            if hasEssay {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("回答完了。")
                        .font(.headline)
                    Text("作成者が記述式を採点中... ⏳")
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

                if let message = question.dmInviteMessage, !message.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("出題者からのメッセージ")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(message)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }

            Spacer()

            if hasEssay {
                // プロフィールタブに移動
                Button(action: {
                    // ★★★ 修正: onCloseを呼び出してから遷移 ★★★
                    onClose?()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // 掲示板タブをルートに戻す
                        navManager.questionPath = NavigationPath()
                        
                        // プロフィールタブに移動
                        navManager.profilePath = NavigationPath()
                        navManager.tabSelection = 3
                    }
                }) {
                    Text("プロフィールへ")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // ★★★ 追加: 掲示板へボタン ★★★
                Button(action: handleBackToBoard) {
                    Text("掲示板へ")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            } else {
                Button(action: {
                    if let action = onDMTap {
                        action()
                    } else {
                        onClose?()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // ★★★ 修正: 掲示板タブもリセット ★★★
                            navManager.questionPath = NavigationPath()
                            navManager.dmPath = NavigationPath()
                            navManager.tabSelection = 2
                        }
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
                
                // ★★★ 追加: 掲示板へボタン ★★★
                Button(action: handleBackToBoard) {
                    Text("掲示板へ")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                // 後でボタン
                Button(action: {
                    showDMGuide = true
                }) {
                    Text("後で")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showDMGuide) {
            DMGuideView(isPresented: $showDMGuide) {
                onClose?()
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navManager.questionPath = NavigationPath()
                    navManager.tabSelection = 0
                }
            }
        }
    }
}
