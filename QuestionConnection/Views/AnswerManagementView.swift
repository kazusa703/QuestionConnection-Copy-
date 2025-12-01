import SwiftUI

struct AnswerManagementView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    let question: Question // 対象の質問
    
    var body: some View {
        List {
            if profileViewModel.isLoadingAnswers {
                ProgressView()
            } else if profileViewModel.answerLogs.isEmpty {
                Text("まだ回答はありません。")
            } else {
                ForEach(profileViewModel.answerLogs) { log in
                    NavigationLink(destination: GradingDetailView(log: log)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("回答者ID: \(log.userId.prefix(8))...") // 本当はニックネーム取得推奨
                                    .font(.headline)
                                Text(statusText(log.status))
                                    .font(.caption)
                                    .foregroundColor(statusColor(log.status))
                            }
                            Spacer()
                            Text("\(log.score) / \(log.total)")
                        }
                    }
                }
            }
        }
        .navigationTitle("回答一覧")
        .task {
            await profileViewModel.fetchAnswerLogs(questionId: question.questionId)
        }
    }
    
    func statusText(_ status: String) -> String {
        switch status {
        case "pending_review": return "⚠️ 採点待ち"
        case "approved": return "✅ 承認済み (DM可)"
        case "rejected": return "❌ 不正解"
        case "completed": return "自動採点完了"
        default: return status
        }
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "pending_review": return .orange
        case "approved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
}

// 詳細・採点画面
struct GradingDetailView: View {
    let log: AnswerLogItem
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("回答詳細").font(.largeTitle).bold()
                
                ForEach(log.details) { detail in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(detail.type == "essay" ? "📝 記述式" : "選択/穴埋め")
                                .font(.caption)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            Spacer()
                            if detail.isCorrect {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        
                        Text("回答:")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(detail.userAnswer?.displayString ?? "")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
                }
                
                // 採点ボタン (未採点の場合のみ表示)
                if log.status == "pending_review" {
                    HStack(spacing: 20) {
                        Button(action: { submitJudge(false) }) {
                            Text("不正解").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        
                        Button(action: { submitJudge(true) }) {
                            Text("正解 (DM許可)").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.top)
                    .disabled(profileViewModel.isJudging)
                } else {
                    Text("採点済み: \(log.status)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    func submitJudge(_ isApproved: Bool) {
        Task {
            let success = await profileViewModel.judgeAnswer(logId: log.logId, isApproved: isApproved)
            if success {
                dismiss()
            }
        }
    }
}
