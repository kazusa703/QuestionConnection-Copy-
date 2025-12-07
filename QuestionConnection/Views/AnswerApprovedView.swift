import SwiftUI

struct AnswerApprovedView: View {
    let log: AnswerLogItem
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dmViewModel: DMViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showModelAnswer = false
    @State private var questionDetail: Question? = nil
    @State private var isFetchingQuestion = false
    
    @State private var navigateToDM = false
    @State private var createdThread: DMThread? = nil
    @State private var showInitialDMView = false
    
    var body: some View {
        VStack(spacing: 20) {
            // ★ 正解表示セクション
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("正解！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("承認されました！")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Divider()
            
            // ★ あなたの回答
            VStack(alignment: .leading, spacing: 8) {
                Text("あなたの回答")
                    .font(.headline)
                
                ForEach(log.details) { detail in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.userAnswer?.displayString ?? "(回答なし)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // ★ 模範解答を見るボタン
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
            
            // ★ メッセージを送るボタン
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
            if let question = questionDetail {
                ModelAnswerView(question: question)
            } else {
                ProgressView()
            }
        }
        .navigationDestination(isPresented: $navigateToDM) {
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
                    .environmentObject(profileViewModel)
            }
        }
        .sheet(isPresented: $showInitialDMView) {
            NavigationStack {
                InitialDMView(
                    recipientId: log.authorId ?? "",
                    questionTitle: log.questionTitle ?? "質問"
                )
                .environmentObject(profileViewModel)
            }
        }
    }
    
    private func fetchAndShowModelAnswer() {
        isFetchingQuestion = true
        Task {
            await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
            await MainActor.run {
                questionDetail = profileViewModel.selectedQuestionForModelAnswer
                isFetchingQuestion = false
                showModelAnswer = true
            }
        }
    }
    
    private func startDM() {
        Task {
            if let authorId = log.authorId {
                if let thread = await dmViewModel.findDMThread(with: authorId) {
                    await MainActor.run {
                        self.createdThread = thread
                        self.navigateToDM = true
                    }
                } else {
                    await MainActor.run {
                        self.showInitialDMView = true
                    }
                }
            }
        }
    }
}
