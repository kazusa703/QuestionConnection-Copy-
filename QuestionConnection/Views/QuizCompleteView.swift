import SwiftUI

struct QuizCompleteView: View {
    let question: Question
    let hasEssay: Bool
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dmViewModel: DMViewModel
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    var onClose: (() -> Void)? = nil
    var onDMTap: (() -> Void)? = nil

    // ★★★ 追加: メッセージ入力用 ★★★
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var showSendSuccess: Bool = false
    @State private var showLaterAlert: Bool = false
    @State private var alreadyHasThread: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if hasEssay {
                    // ★★★ 記述式の場合（変更なし） ★★★
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("回答完了。")
                            .font(.headline)
                        Text("作成者が記述式を採点中... ⏳")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("採点結果は「プロフィール」→\n「記述式問題の結果」から確認できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding(20)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // OKボタン
                    Button(action: {
                        print("🔵 [QuizCompleteView] OKボタンがタップされました")
                        NotificationCenter.default.post(name: .forcePopToBoard, object: nil)
                    }) {
                        Text("OK")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                } else {
                    // ★★★ 全問正解（記述式なし）の場合 ★★★
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

                    // 出題者からのメッセージがあれば表示
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
                    
                    // ★★★ 追加: メッセージ入力欄 ★★★
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出題者にメッセージを送る")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $messageText)
                            .frame(height: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        if messageText.isEmpty {
                            Text("メッセージを入力してください")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // ★★★ 送信成功メッセージ ★★★
                    if showSendSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("メッセージを送信しました！")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // ★★★ メッセージを送るボタン ★★★
                    Button(action: {
                        print("🔵 [QuizCompleteView] メッセージを送るボタンがタップされました")
                        Task {
                            await sendMessage()
                        }
                    }) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("メッセージを送る")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                    
                    // ★★★ 後でボタン ★★★
                    Button(action: {
                        print("🔵 [QuizCompleteView] 後でボタンがタップされました")
                        Task {
                            await checkExistingThread()
                            showLaterAlert = true
                        }
                    }) {
                        Text("後で")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            print("🔵 [QuizCompleteView] 画面が表示されました hasEssay=\(hasEssay)")
        }
        // ★★★ 後でアラート ★★★
        .alert("後で送信", isPresented: $showLaterAlert) {
            Button("OK") {
                print("🔵 [QuizCompleteView] 後でアラートOKがタップされました")
                NotificationCenter.default.post(name: .forcePopToBoard, object: nil)
            }
        } message: {
            if alreadyHasThread {
                Text("DMタブから出題者にメッセージを送れます。")
            } else {
                Text("後で送る場合は「DM」タブの「未送信」ボタンからDMできます。")
            }
        }
    }
    
    // ★★★ メッセージ送信処理 ★★★
    private func sendMessage() async {
        print("🔵 [QuizCompleteView] sendMessage() 開始")
        
        guard let myUserId = authViewModel.userSub else {
            print("🔵 [QuizCompleteView] エラー: userSub が nil")
            return
        }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            print("🔵 [QuizCompleteView] エラー: メッセージが空")
            return
        }
        
        isSending = true
        print("🔵 [QuizCompleteView] DM送信中... recipientId=\(question.authorId), senderId=\(myUserId)")
        
        let thread = await dmViewModel.sendInitialDMAndReturnThread(
            recipientId: question.authorId,
            senderId: myUserId,
            questionTitle: question.title,
            messageText: trimmedMessage
        )
        
        isSending = false
        
        if thread != nil {
            print("🔵 [QuizCompleteView] DM送信成功！")
            showSendSuccess = true
            messageText = ""
            
            // 少し待ってからBoardViewに戻る
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("🔵 [QuizCompleteView] BoardViewに戻ります")
                NotificationCenter.default.post(name: .forcePopToBoard, object: nil)
            }
        } else {
            print("🔵 [QuizCompleteView] DM送信失敗")
        }
    }
    
    // ★★★ 既存スレッド確認 ★★★
    private func checkExistingThread() async {
        print("🔵 [QuizCompleteView] checkExistingThread() 開始")
        let existingThread = await dmViewModel.findDMThread(with: question.authorId)
        alreadyHasThread = (existingThread != nil)
        print("🔵 [QuizCompleteView] alreadyHasThread=\(alreadyHasThread)")
    }
}
