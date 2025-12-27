import SwiftUI

// MARK: - AnswerApprovedView

struct AnswerApprovedView: View {
    let log: AnswerLogItem
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dmViewModel: DMViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showModelAnswer = false
    @State private var questionDetail: Question? = nil
    @State private var navigateToDM = false
    @State private var createdThread: DMThread? = nil
    @State private var showInitialDMView = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("正解！")
                    .font(.title).fontWeight(.bold).foregroundColor(.green)
                Text("承認されました！")
                    .font(.headline).foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Divider()
            
            answerDetailsSection
            
            Button(action: fetchAndShowModelAnswer) {
                HStack {
                    Image(systemName: "book.fill")
                    Text("模範解答を見る")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: startDM) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("メッセージを送る")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("回答承認")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showModelAnswer) {
            if let question = questionDetail { ModelAnswerView(question: question) }
            else { ProgressView() }
        }
        .navigationDestination(isPresented: $navigateToDM) {
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
                    .environmentObject(profileViewModel)
            }
        }
        .sheet(isPresented: $showInitialDMView) {
            NavigationStack {
                InitialDMView(recipientId: log.authorId ?? "", questionTitle: log.questionTitle ?? "質問")
                    .environmentObject(profileViewModel)
            }
        }
    }
    
    private var answerDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたの回答").font(.headline)
            ForEach(log.details) { detail in
                VStack(alignment: .leading, spacing: 8) {
                    if let questionText = detail.questionText, !questionText.isEmpty {
                        Text("Q: \(questionText)")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    Text(detail.type == "essay" ? "記述式" : (detail.type == "choice" ? "選択式" : "穴埋め"))
                        .font(.caption).foregroundColor(.secondary)
                    Text(detail.userAnswer?.displayString ?? "(回答なし)")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    private func fetchAndShowModelAnswer() {
        Task {
            await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
            await MainActor.run {
                questionDetail = profileViewModel.selectedQuestionForModelAnswer
                showModelAnswer = true
            }
        }
    }
    
    private func startDM() {
        Task {
            if let authorId = log.authorId {
                if let thread = await dmViewModel.findDMThread(with: authorId) {
                    await MainActor.run { createdThread = thread; navigateToDM = true }
                } else {
                    await MainActor.run { showInitialDMView = true }
                }
            }
        }
    }
}

// MARK: - AnswerPendingView

struct AnswerPendingView: View {
    let log: AnswerLogItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text("採点待ち")
                    .font(.title).fontWeight(.bold)
                Text("出題者が記述式問題を採点中です。\nしばらくお待ちください。")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("あなたの回答").font(.headline)
                ForEach(log.details.filter { $0.type == "essay" }) { detail in
                    VStack(alignment: .leading, spacing: 8) {
                        if let questionText = detail.questionText, !questionText.isEmpty {
                            Text("Q: \(questionText)")
                                .font(.subheadline).fontWeight(.medium)
                        }
                        Text("記述式問題")
                            .font(.caption).foregroundColor(.secondary)
                        Text(detail.userAnswer?.displayString ?? "(回答なし)")
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
            
            if let questionTitle = log.questionTitle {
                HStack {
                    Image(systemName: "questionmark.circle").foregroundColor(.secondary)
                    Text(questionTitle).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                .padding(.horizontal)
            }
            
            Button(action: { dismiss() }) {
                Text("閉じる")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("回答状況")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AnswerResultView

struct AnswerResultView: View {
    let log: AnswerLogItem
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @State private var navigateToDM = false
    @State private var createdThread: DMThread?
    @State private var showModelAnswer = false
    @State private var questionDetail: Question?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusHeader
                
                Text("あなたの回答").font(.headline)
                
                ForEach(log.details) { detail in
                    detailCard(detail)
                }
                
                Divider()
                
                actionArea
            }
            .padding()
        }
        .navigationTitle("回答結果")
        .task {
            if log.status == "approved" && questionDetail == nil {
                await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
                await MainActor.run { questionDetail = profileViewModel.selectedQuestionForModelAnswer }
            }
        }
        .sheet(isPresented: $showModelAnswer) {
            if let q = questionDetail { ModelAnswerView(question: q) }
            else { ProgressView() }
        }
        .navigationDestination(isPresented: $navigateToDM) {
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
            }
        }
    }
    
    private var statusHeader: some View {
        HStack {
            if log.status == "approved" {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                Text("正解！承認されました").font(.title2).bold().foregroundColor(.green)
            } else if log.status == "rejected" {
                Image(systemName: "xmark.seal.fill").foregroundColor(.red)
                Text("不正解").font(.title2).bold().foregroundColor(.red)
            } else {
                Image(systemName: "hourglass").foregroundColor(.orange)
                Text("採点待ち").font(.title2).bold().foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func detailCard(_ detail: AnswerDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let questionText = detail.questionText, !questionText.isEmpty {
                Text("Q: \(questionText)")
                    .font(.subheadline).fontWeight(.medium)
            }
            Text(detail.type == "essay" ? "記述式" : (detail.type == "choice" ? "選択式" : "穴埋め"))
                .font(.caption).foregroundColor(.secondary)
            Text(detail.userAnswer?.displayString ?? "(回答なし)")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(detail.isCorrect ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                .cornerRadius(8)
            HStack {
                Image(systemName: detail.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(detail.isCorrect ? .green : .red)
                Text(detail.isCorrect ? "正解" : "不正解")
                    .font(.caption).foregroundColor(detail.isCorrect ? .green : .red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
    
    @ViewBuilder
    private var actionArea: some View {
        if log.status == "approved" {
            VStack(spacing: 16) {
                if let message = questionDetail?.dmInviteMessage, !message.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("作成者からのメッセージ", systemImage: "quote.bubble.fill")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(message)
                            .font(.body).padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                Button(action: startDM) {
                    HStack { Image(systemName: "envelope.fill"); Text("メッセージを送る") }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }
            }
        } else if log.status == "rejected" {
            Button(action: fetchModelAnswer) {
                HStack { Image(systemName: "doc.text.magnifyingglass"); Text("模範解答を見る") }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.orange).foregroundColor(.white).cornerRadius(10)
            }
        }
    }
    
    func startDM() {
        Task {
            if let authorId = log.authorId,
               let thread = await dmViewModel.findDMThread(with: authorId) {
                await MainActor.run { createdThread = thread; navigateToDM = true }
            }
        }
    }
    
    func fetchModelAnswer() {
        showModelAnswer = true
        Task {
            if questionDetail == nil {
                await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
                await MainActor.run { questionDetail = profileViewModel.selectedQuestionForModelAnswer }
            }
        }
    }
}

// MARK: - Preview Sample

extension AnswerLogItem {
    static var previewSample: AnswerLogItem {
        let json = """
        {"logId":"1","userId":"user1","status":"pending_review","score":0,"total":3,"updatedAt":"2025-01-01","details":[],"questionId":"q1","questionTitle":"テスト質問"}
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(AnswerLogItem.self, from: json)
    }
}
