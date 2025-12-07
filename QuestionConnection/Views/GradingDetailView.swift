import SwiftUI

struct GradingDetailView: View {
    let log: AnswerLogItem
    
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var essayGrades: [String: Bool] = [:]
    @State private var showGradingNotification = false
    @State private var navigateToDM = false
    @State private var createdThread: DMThread?
    
    // ★★★ State変数に追加 ★★★
    @State private var showInitialDMView = false
    
    private var essayDetails: [AnswerDetail] {
        log.details.filter { $0.type == "essay" }
    }
    
    private var autoGradedDetails: [AnswerDetail] {
        log.details.filter { $0.type != "essay" }
    }
    
    private var allEssaysGraded: Bool {
        essayDetails.allSatisfy { essayGrades[$0.itemId] != nil }
    }
    
    private var allEssaysApproved: Bool {
        essayDetails.allSatisfy { essayGrades[$0.itemId] == true }
    }
    
    private var allAutoGradedCorrect: Bool {
        autoGradedDetails.allSatisfy { $0.isCorrect }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                if !autoGradedDetails.isEmpty {
                    autoGradedSection
                }
                
                if !essayDetails.isEmpty {
                    essayGradingSection
                }
                
                summarySection
                submitButton
            }
            .padding()
        }
        .navigationTitle("回答詳細")
        .navigationBarTitleDisplayMode(.inline)
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
        // ★★★ body内のsheet修正（showGradingNotificationの後に追加）★★★
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
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let nickname = log.userNickname, !nickname.isEmpty {
                        Text(nickname)
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("ID: \(log.userId.prefix(8))...")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(statusText(log.status))
                        .font(.subheadline)
                        .foregroundColor(statusColor(log.status))
                }
                
                Spacer()
            }
            
            Divider()
        }
    }
    
    private var autoGradedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自動採点結果")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(autoGradedDetails) { detail in
                HStack {
                    Image(systemName: detail.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(detail.isCorrect ? .green : .red)
                    
                    Text(detail.type == "choice" ? "選択式" : "穴埋め")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(detail.isCorrect ? "正解" : "不正解")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(detail.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var essayGradingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("記述式問題の採点")
                    .font(.headline)
                
                Spacer()
                
                Text("\(essayGrades.count)/\(essayDetails.count) 採点済み")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(Array(essayDetails.enumerated()), id: \.element.itemId) { index, detail in
                essayCard(detail: detail, index: index + 1)
            }
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("全ての記述式問題が正解の場合のみ、回答者に通知が送られます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func essayCard(detail: AnswerDetail, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝 記述式問題 \(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let isApproved = essayGrades[detail.itemId] {
                    Text(isApproved ? "✅ 正解" : "❌ 不正解")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isApproved ? .green : .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("回答:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(detail.userAnswer?.displayString ?? "(回答なし)")
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        essayGrades[detail.itemId] = true
                    }
                }) {
                    HStack {
                        Image(systemName: essayGrades[detail.itemId] == true ? "checkmark.circle.fill" : "circle")
                        Text("正解")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(essayGrades[detail.itemId] == true ? Color.green : Color.green.opacity(0.1))
                    .foregroundColor(essayGrades[detail.itemId] == true ? .white : .green)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    withAnimation {
                        essayGrades[detail.itemId] = false
                    }
                }) {
                    HStack {
                        Image(systemName: essayGrades[detail.itemId] == false ? "xmark.circle.fill" : "circle")
                        Text("不正解")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(essayGrades[detail.itemId] == false ? Color.red : Color.red.opacity(0.1))
                    .foregroundColor(essayGrades[detail.itemId] == false ? .white : .red)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                Text("採点サマリー")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("選択式/穴埋め")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(autoGradedDetails.filter { $0.isCorrect }.count)/\(autoGradedDetails.count) 正解")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("記述式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if allEssaysGraded {
                        let approvedCount = essayGrades.values.filter { $0 }.count
                        Text("\(approvedCount)/\(essayDetails.count) 正解")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("採点中...")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var submitButton: some View {
        VStack(spacing: 12) {
            Button(action: submitGrading) {
                HStack {
                    if profileViewModel.isJudging {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                        Text("採点完了")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(allEssaysGraded ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!allEssaysGraded || profileViewModel.isJudging)
            
            if !allEssaysGraded {
                Text("全ての記述式問題を採点してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Functions
    
    private func initializeEssayGrades() {
        for detail in essayDetails {
            if detail.status == "approved" {
                essayGrades[detail.itemId] = true
            } else if detail.status == "rejected" {
                essayGrades[detail.itemId] = false
            }
        }
    }
    
    // GradingDetailView.swift の submitGrading 関数を以下に置き換え

    private func submitGrading() {
        Task {
            let success = await profileViewModel.submitEssayGrades(
                logId: log.logId,
                essayGrades: essayGrades
            )
            
            if success {
                let allAutoCorrect = autoGradedDetails.allSatisfy { $0.isCorrect }
                let allEssayCorrect = essayGrades.values.allSatisfy { $0 == true }
                
                if allAutoCorrect && allEssayCorrect {
                    showGradingNotification = true
                } else {
                    dismiss()
                }
            } else {
                print("採点の送信に失敗しました")
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
        case "pending_review": return "⚠️ 採点待ち"
        case "approved": return "✅ 承認済み"
        case "rejected": return "❌ 不正解"
        case "completed": return "✅ 自動採点完了"
        default: return status
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending_review": return . orange
        case "approved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
}
