import SwiftUI

// MARK: - QuizCompleteView

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

    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var showSendSuccess: Bool = false
    @State private var showLaterAlert: Bool = false
    @State private var alreadyHasThread: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if hasEssay {
                    essayPendingContent
                } else {
                    allCorrectContent
                }
            }
            .padding(24)
        }
        .alert("後で送信", isPresented: $showLaterAlert) {
            Button("OK") {
                NotificationCenter.default.post(name: .forcePopToBoard, object: nil)
            }
        } message: {
            Text(alreadyHasThread ? "DMタブから出題者にメッセージを送れます。" : "後で送る場合は「DM」タブの「未送信」ボタンからDMできます。")
        }
    }
    
    private var essayPendingContent: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(.green)
                Text("回答完了。").font(.headline)
                Text("作成者が記述式を採点中... ⏳")
                    .font(.subheadline).foregroundColor(.secondary)
                Text("採点結果は「プロフィール」→\n「記述式問題の結果」から確認できます")
                    .font(.caption).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.top, 8)
            }
            .padding(20)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Button(action: { NotificationCenter.default.post(name: .forcePopToBoard, object: nil) }) {
                Text("OK")
                    .frame(maxWidth: .infinity).padding(12)
                    .background(Color.blue).foregroundColor(.white).cornerRadius(8)
            }
        }
    }
    
    private var allCorrectContent: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(.green)
                Text("おめでとうございます！").font(.headline)
                Text("全問正解です！").font(.headline)
            }
            .padding(20)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            if let message = question.dmInviteMessage, !message.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill").foregroundColor(.blue)
                        Text("出題者からのメッセージ").font(.subheadline).fontWeight(.medium)
                    }
                    Text(message).font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("出題者にメッセージを送る").font(.subheadline).fontWeight(.medium)
                TextEditor(text: $messageText)
                    .frame(height: 100).padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                if messageText.isEmpty {
                    Text("メッセージを入力してください").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
            
            if showSendSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("メッセージを送信しました！").font(.subheadline)
                }
                .padding().background(Color.green.opacity(0.1)).cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: { Task { await sendMessage() } }) {
                HStack {
                    if isSending { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    else { Image(systemName: "paperplane.fill"); Text("メッセージを送る") }
                }
                .frame(maxWidth: .infinity).padding(12)
                .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? Color.gray : Color.blue)
                .foregroundColor(.white).cornerRadius(8)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            
            Button(action: { Task { await checkExistingThread(); showLaterAlert = true } }) {
                Text("後で").frame(maxWidth: .infinity).padding(12).foregroundColor(.secondary)
            }
        }
    }
    
    private func sendMessage() async {
        guard let myUserId = authViewModel.userSub else { return }
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        isSending = true
        let thread = await dmViewModel.sendInitialDMAndReturnThread(
            recipientId: question.authorId,
            senderId: myUserId,
            questionTitle: question.title,
            messageText: trimmedMessage
        )
        isSending = false
        
        if thread != nil {
            showSendSuccess = true
            messageText = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationCenter.default.post(name: .forcePopToBoard, object: nil)
            }
        }
    }
    
    private func checkExistingThread() async {
        let existingThread = await dmViewModel.findDMThread(with: question.authorId)
        alreadyHasThread = (existingThread != nil)
    }
}

// MARK: - QuizIncorrectView

struct QuizIncorrectView: View {
    let currentItem: QuizItem
    let userAnswer: [String: String]
    let questionId: String
    var onClose: (() -> Void)? = nil
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(.red)
                Text("不正解です ✗").font(.headline)
            }
            .padding(20)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 12) {
                Text("正解:").font(.subheadline).fontWeight(.bold)
                Text(getCorrectAnswerText())
                    .font(.body).padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1)).cornerRadius(8)

                Divider()

                Text("あなたの回答:").font(.subheadline).fontWeight(.bold)
                Text(getUserAnswerText())
                    .font(.body).padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1)).cornerRadius(8)
            }
            .padding()

            Spacer()

            Button(action: {
                NotificationCenter.default.post(name: .forcePopToBoard, object: questionId)
            }) {
                Text("終了")
                    .frame(maxWidth: .infinity).padding(12)
                    .background(Color.gray.opacity(0.3)).foregroundColor(.primary).cornerRadius(8)
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.6)])
    }

    private func getCorrectAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            return currentItem.choices.first(where: { $0.id == currentItem.correctAnswerId })?.text ?? "N/A"
        case .fillIn:
            let sortedAnswers = currentItem.fillInAnswers.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
            return sortedAnswers.map { "(\($0.key)) \($0.value)" }.joined(separator: ", ")
        case .essay:
            return currentItem.modelAnswer ?? "N/A"
        }
    }

    private func getUserAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            let selectedId = userAnswer["choice"] ?? ""
            return currentItem.choices.first(where: { $0.id == selectedId })?.text ?? "未回答"
        case .fillIn:
            let sortedKeys = userAnswer.keys.sorted { (Int($0) ?? 0) < (Int($1) ?? 0) }
            let answers = sortedKeys.compactMap { key -> String? in
                if let value = userAnswer[key], !value.isEmpty { return "(\(key)) \(value)" }
                return nil
            }
            return answers.isEmpty ? "未回答" : answers.joined(separator: ", ")
        case .essay:
            return userAnswer["essay"] ?? "未回答"
        }
    }
}
