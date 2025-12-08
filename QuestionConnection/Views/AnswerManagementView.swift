import SwiftUI

struct AnswerManagementView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let question: Question
    
    // フィルタリング用ステート
    @State private var showOnlyPending = false
    
    var filteredLogs: [AnswerLogItem] {
        if showOnlyPending {
            return profileViewModel.answerLogs.filter { $0.status == "pending_review" }
        }
        return profileViewModel.answerLogs
    }
    
    var body: some View {
        VStack {
            // フィルタリングトグル
            HStack {
                Spacer()
                Button(action: { showOnlyPending.toggle() }) {
                    HStack {
                        Image(systemName: showOnlyPending ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        Text(showOnlyPending ? "未採点のみ表示中" : "採点する（未採点を表示）")
                    }
                    .padding(8)
                    .background(showOnlyPending ? Color.orange.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            List {
                if profileViewModel.isLoadingAnswers {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if filteredLogs.isEmpty {
                    Text(showOnlyPending ? "未採点の回答はありません" : "回答はありません")
                        .foregroundColor(.secondary)
                        .padding()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredLogs) { log in
                        NavigationLink(destination: GradingDetailView(log: log)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    if let nickname = log.userNickname, !nickname.isEmpty {
                                        Text(nickname).font(.headline)
                                    } else {
                                        Text("ID: \(log.userId.prefix(6))...").font(.subheadline)
                                    }
                                    Text(statusText(log.status))
                                        .font(.caption)
                                        .foregroundColor(statusColor(log.status))
                                }
                                Spacer()
                                // 記述式が含まれる場合はスコアより「未採点」を強調しても良い
                                if log.status == "pending_review" {
                                    Image(systemName: "pencil").foregroundColor(.orange)
                                } else {
                                    Text("\(log.score)/\(log.total)")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("回答管理")
        .task {
            await profileViewModel.fetchAnswerLogs(questionId: question.questionId)
        }
    }
    
    private func statusText(_ status: String) -> String {
        switch status {
        case "pending_review": return "⚠️ 採点待ち"
        case "approved": return "✅ 承認済み"
        case "rejected": return "❌ 不正解"
        case "rejected_auto": return "❌ 自動採点で不正解"
        case "completed": return "✅ 完了"
        default: return status
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending_review": return .orange
        case "approved": return .green
        case "rejected", "rejected_auto": return .red
        default: return .gray
        }
    }
}
