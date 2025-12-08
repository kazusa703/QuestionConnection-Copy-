import SwiftUI

struct GradingDetailView: View {
    let log: AnswerLogItem
    
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 記述式の採点状態（true: 正解, false: 不正解）
    @State private var essayGrades: [String: Bool] = [:]
    
    @State private var showGradingNotification = false
    @State private var navigateToDM = false
    @State private var createdThread: DMThread?
    @State private var showInitialDMView = false
    
    // 記述式のみ抽出
    private var essayDetails: [AnswerDetail] {
        log.details.filter { $0.type == "essay" }
    }
    
    // 自動採点（選択・穴埋め）のみ抽出
    private var autoGradedDetails: [AnswerDetail] {
        log.details.filter { $0.type != "essay" }
    }
    
    // 全ての記述式が採点済みか判定
    private var allEssaysGraded: Bool {
        essayDetails.allSatisfy { essayGrades[$0.itemId] != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. ヘッダー（回答者情報）
                headerSection
                
                // 2. 自動採点エリア（選択式・穴埋め）
                // ここで「不正解」があっても、下の記述式で挽回可能です
                if !autoGradedDetails.isEmpty {
                    autoGradedSection
                }
                
                // 3. 記述式採点エリア
                // ここでの評価が最終合否を決めます
                if !essayDetails.isEmpty {
                    essayGradingSection
                }
                
                // 4. 採点実行ボタン
                submitButtonSection
            }
            .padding()
        }
        .navigationTitle("回答詳細")
        .navigationBarTitleDisplayMode(.inline)
        // 完了後の通知・遷移
        .sheet(isPresented: $showGradingNotification) {
            GradingNotificationView(
                isPresented: $showGradingNotification,
                onSendMessage: {
                    showGradingNotification = false
                    startDM()
                },
                onLater: {
                    showGradingNotification = false
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showInitialDMView) {
            NavigationStack {
                InitialDMView(
                    recipientId: log.userId,
                    questionTitle: log.questionTitle ?? "質問"
                )
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
            }
        }
        .navigationDestination(isPresented: $navigateToDM) {
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
            }
        }
        .onAppear {
            initializeEssayGrades()
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 4) {
                if let nickname = log.userNickname, !nickname.isEmpty {
                    Text(nickname)
                        .font(.title3)
                        .fontWeight(.bold)
                } else {
                    Text("ID: \(log.userId.prefix(8))...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text(statusText(log.status))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(log.status).opacity(0.1))
                    .foregroundColor(statusColor(log.status))
                    .cornerRadius(4)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var autoGradedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自動採点の結果")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(autoGradedDetails) { detail in
                HStack {
                    Image(systemName: detail.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(detail.isCorrect ? .green : .red)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detail.type == "choice" ? "選択式" : "穴埋め")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(detail.userAnswer?.displayString ?? "(回答なし)")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text(detail.isCorrect ? "正解" : "不正解")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(detail.isCorrect ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(detail.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var essayGradingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("記述式の採点")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("残り \(essayDetails.count - essayGrades.count) 問")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(Array(essayDetails.enumerated()), id: \.element.itemId) { index, detail in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Q\(index + 1) (記述式)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(detail.userAnswer?.displayString ?? "(回答なし)")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        // 不正解ボタン
                        Button(action: {
                            withAnimation { essayGrades[detail.itemId] = false }
                        }) {
                            HStack {
                                Image(systemName: essayGrades[detail.itemId] == false ? "xmark.circle.fill" : "circle")
                                Text("不正解")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(essayGrades[detail.itemId] == false ? Color.red.opacity(0.1) : Color.clear)
                            .foregroundColor(essayGrades[detail.itemId] == false ? .red : .gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(essayGrades[detail.itemId] == false ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        
                        // 正解ボタン
                        Button(action: {
                            withAnimation { essayGrades[detail.itemId] = true }
                        }) {
                            HStack {
                                Image(systemName: essayGrades[detail.itemId] == true ? "checkmark.circle.fill" : "circle")
                                Text("正解 (承認)")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(essayGrades[detail.itemId] == true ? Color.green.opacity(0.1) : Color.clear)
                            .foregroundColor(essayGrades[detail.itemId] == true ? .green : .gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(essayGrades[detail.itemId] == true ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var submitButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: submitGrading) {
                HStack {
                    if profileViewModel.isJudging {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                        Text("採点を確定する")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(allEssaysGraded ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!allEssaysGraded || profileViewModel.isJudging)
            
            // 注釈（作成者の判断基準を補足）
            if allEssaysGraded {
                let approved = essayGrades.values.allSatisfy { $0 }
                if approved {
                    VStack(spacing: 4) {
                        Text("※ 「正解」として回答者に通知され、DMが可能になります。")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        Text("（自動採点の結果に関わらず合格となります）")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("※ 「不正解」として通知されます。DMはできません。")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Text("すべての記述式問題を判定してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Logic
    
    private func initializeEssayGrades() {
        for detail in essayDetails {
            if detail.status == "approved" {
                essayGrades[detail.itemId] = true
            } else if detail.status == "rejected" {
                essayGrades[detail.itemId] = false
            }
        }
    }
    
    private func submitGrading() {
        Task {
            // サーバーへ送信 (記述式の結果に基づいて合否が決まる)
            let success = await profileViewModel.submitEssayGrades(
                logId: log.logId,
                essayGrades: essayGrades
            )
            
            if success {
                // ★★★ 修正: 記述式が全て正解なら、自動採点の結果に関わらず「合格」とする ★★★
                let allEssayCorrect = essayGrades.values.allSatisfy { $0 == true }
                
                if allEssayCorrect {
                    showGradingNotification = true
                } else {
                    dismiss()
                }
            } else {
                print("採点送信失敗")
            }
        }
    }
    
    private func startDM() {
        Task {
            if let thread = await dmViewModel.findDMThread(with: log.userId) {
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
    
    private func statusText(_ status: String) -> String {
        switch status {
        case "pending_review": return "未採点"
        case "approved": return "承認済み"
        case "rejected": return "不正解"
        default: return ""
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
