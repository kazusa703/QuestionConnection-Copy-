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
                } else if filteredLogs.isEmpty {
                    Text(showOnlyPending ? "未採点の回答はありません" : "回答はありません")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(filteredLogs) { log in
                        NavigationLink(destination: GradingDetailView(log: log)
                            .environmentObject(profileViewModel)
                            .environmentObject(dmViewModel)
                            .environmentObject(authViewModel)
                        ) {
                            AnswerLogRowView(log: log)
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
        .refreshable {
            await profileViewModel.fetchAnswerLogs(questionId: question.questionId)
        }
    }
}

// 回答者一覧の行ビュー
struct AnswerLogRowView: View {
    let log: AnswerLogItem
    
    var body: some View {
        HStack {
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                if let nickname = log.userNickname, !nickname.isEmpty {
                    Text(nickname)
                        .font(.headline)
                } else {
                    Text("ID: \(log.userId.prefix(8))...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(statusText(log.status))
                    .font(.caption)
                    .foregroundColor(statusColor(log.status))
            }
            
            Spacer()
            
            // スコアまたはステータスアイコン
            if log.status == "pending_review" {
                // 記述式が含まれる場合は採点アイコン
                HStack(spacing: 4) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                    Text("採点待ち")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                // 採点済みの場合はスコア表示
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(log.score)/\(log.total)")
                        .font(.headline)
                        .foregroundColor(log.status == "approved" ? .green : .red)
                    
                    if log.status == "approved" {
                        Text("DM可")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private func statusText(_ status: String) -> String {
        switch status {
        case "pending_review": return "⚠️ 採点待ち"
        case "approved": return "✅ 承認済み"
        case "rejected": return "❌ 不正解"
        case "completed": return "✅ 完了"
        default: return status
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending_review": return .orange
        case "approved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
}
