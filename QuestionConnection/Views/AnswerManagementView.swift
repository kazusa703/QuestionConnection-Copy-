import SwiftUI

struct AnswerManagementView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    // ★ DMViewModelを親から受け取るために定義
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let question: Question // 対象の質問
    
    var body: some View {
        List {
            if profileViewModel.isLoadingAnswers {
                ProgressView()
            } else if profileViewModel.answerLogs.isEmpty {
                Text("まだ回答はありません。")
            } else {
                ForEach(profileViewModel.answerLogs) { log in
                    // ★ GradingDetailView に dmViewModel を渡す必要はありません
                    // (EnvironmentObjectとして定義しておけば自動で引き継がれます)
                    NavigationLink(destination: GradingDetailView(log: log)) {
                        HStack {
                            VStack(alignment: .leading) {
                                // ★ 修正: ニックネームがあれば表示、なければIDの一部を表示
                                if let nickname = log.userNickname, !nickname.isEmpty {
                                    Text(nickname)
                                        .font(.headline)
                                } else {
                                    Text("回答者ID: \(log.userId.prefix(8))...")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                
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
    // ★ DM機能を使うために追加
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // DM遷移・アラート用
    @State private var showDMAlert = false
    @State private var navigateToDM = false
    @State private var createdThread: DMThread? // ★ ここは DMThread? (型)
    
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
                    // アラートと遷移のコード
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
                        
                        // ★ 追加: 正解(approved)ならDMボタンを表示
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
        // ★ ここでも遷移できるように navigationDestination が必要
        // (ただし同じ View 内に .navigationDestination は1つが良いので、
        //  外側の ScrollView や VStack につけるのが安全です)
        .navigationDestination(isPresented: $navigateToDM) { // ★ 遷移先定義を一箇所にまとめる
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
            }
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
    
    func startDM() {
        Task {
            // ★★★ 修正: 名前を findDMThread に変更 ★★★
            // Note: DMViewModelに findDMThread(with:) メソッドが実装されている必要があります
            if let thread = await dmViewModel.findDMThread(with: log.userId) {
                self.createdThread = thread
                self.navigateToDM = true
            } else {
                print("スレッドが見つかりませんでした")
                // 必要に応じて新規作成画面へ遷移などの処理
            }
        }
    }
}
