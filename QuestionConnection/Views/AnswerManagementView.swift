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
            // フィルタリングトグル（またはボタン）
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
                    ProgressView()
                } else if filteredLogs.isEmpty {
                    Text(showOnlyPending ? "未採点の回答はありません" : "回答はありません")
                        .foregroundColor(.secondary)
                        .padding()
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
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // DM遷移・アラート用
    @State private var showDMAlert = false
    @State private var navigateToDM = false
    @State private var createdThread: DMThread?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ★★★ 修正ポイント1: 隠しナビゲーションリンクを追加 ★★★
                NavigationLink(
                    destination: conversationDestination,
                    isActive: $navigateToDM
                ) {
                    EmptyView()
                }
                .hidden()
                
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
                
                // ボタン表示エリア
                if log.status == "pending_review" {
                    // 未採点の場合
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
                    // アラートの表示
                    .alert("正解にしました", isPresented: $showDMAlert) {
                        Button("メッセージを送る") {
                            startDM()
                        }
                        Button("あとで", role: .cancel) {
                            dismiss()
                        }
                    } message: {
                        Text("回答者と会話を始めましょう！")
                    }
                    
                } else {
                    // 採点済みの場合
                    VStack(spacing: 12) {
                        Text("採点済み: \(log.status)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        // 正解(approved)ならDMボタンを表示
                        if log.status == "approved" {
                            Button(action: startDM) {
                                Label("DMへ移動", systemImage: "envelope.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // ★★★ 修正ポイント2: 遷移先ビューを定義 ★★★
    @ViewBuilder
    private var conversationDestination: some View {
        if let thread = createdThread {
            ConversationView(thread: thread, viewModel: dmViewModel)
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
        } else {
            EmptyView()
        }
    }
    
    func submitJudge(_ isApproved: Bool) {
        Task {
            let success = await profileViewModel.judgeAnswer(logId: log.logId, isApproved: isApproved)
            if success {
                if isApproved {
                    showDMAlert = true // 正解ならアラート表示
                } else {
                    dismiss() // 不正解なら閉じる
                }
            }
        }
    }
    
    // ★★★ 修正ポイント3: UI更新をメインスレッドで実行 ★★★
    func startDM() {
        Task {
            if let thread = await dmViewModel.findDMThread(with: log.userId) {
                await MainActor.run {
                    self.createdThread = thread
                    self.navigateToDM = true
                }
            } else {
                print("スレッドが見つかりませんでした")
            }
        }
    }
}
