import SwiftUI

// MARK: - GradingNotificationView (統合)

private struct GradingNotificationView: View {
    @Binding var isPresented: Bool
    let onSendMessage: () -> Void
    let onLater: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("正解にしました")
                    .font(.title).fontWeight(.bold)
                Text("回答者と会話を始めましょう！")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onSendMessage) {
                    HStack { Image(systemName: "envelope.fill"); Text("メッセージを送る") }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                }
                Button(action: onLater) {
                    Text("あとで")
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.gray.opacity(0.1)).foregroundColor(.primary).cornerRadius(12)
                }
            }
        }
        .padding(24)
        .presentationDetents([.fraction(0.55)])
    }
}

// MARK: - GradingDetailView

struct GradingDetailView: View {
    let log: AnswerLogItem
    
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var pendingDMManager: PendingDMManager
    
    @State private var essayGrades: [String: Bool] = [:]
    @State private var showGradingNotification = false
    @State private var showInitialDMView = false
    
    private var essayDetails: [AnswerDetail] { log.details.filter { $0.type == "essay" } }
    private var autoGradedDetails: [AnswerDetail] { log.details.filter { $0.type != "essay" } }
    private var allEssaysGraded: Bool { essayDetails.allSatisfy { essayGrades[$0.itemId] != nil } }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if !autoGradedDetails.isEmpty { autoGradedSection }
                if !essayDetails.isEmpty { essayGradingSection }
                submitButtonSection
            }
            .padding()
        }
        .navigationTitle("回答詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showGradingNotification) {
            GradingNotificationView(
                isPresented: $showGradingNotification,
                onSendMessage: { showGradingNotification = false; refreshPendingList(); startDM() },
                onLater: { showGradingNotification = false; refreshPendingList(); dismiss() }
            )
        }
        .sheet(isPresented: $showInitialDMView) {
            NavigationStack {
                InitialDMView(recipientId: log.userId, questionTitle: log.questionTitle ?? "質問")
                    .environmentObject(authViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(navManager)
            }
        }
        .onAppear { initializeEssayGrades() }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable().frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 4) {
                if let nickname = log.userNickname, !nickname.isEmpty {
                    Text(nickname).font(.title3).fontWeight(.bold)
                } else {
                    Text("ID: \(log.userId.prefix(8))...").font(.headline).foregroundColor(.secondary)
                }
                Text(statusText(log.status))
                    .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(statusColor(log.status).opacity(0.1))
                    .foregroundColor(statusColor(log.status)).cornerRadius(4)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var autoGradedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("自動採点の結果").font(.headline).foregroundColor(.secondary)
            ForEach(autoGradedDetails) { detail in
                HStack {
                    Image(systemName: detail.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(detail.isCorrect ? .green : .red).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detail.type == "choice" ? "選択式" : "穴埋め").font(.caption).foregroundColor(.secondary)
                        Text(detail.userAnswer?.displayString ?? "(回答なし)").font(.body).fontWeight(.medium)
                    }
                    Spacer()
                    Text(detail.isCorrect ? "正解" : "不正解")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(detail.isCorrect ? .green : .red)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(detail.isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
    }
    
    private var essayGradingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("記述式の採点").font(.headline)
                Spacer()
                Text("残り \(essayDetails.count - essayGrades.count) 問").font(.caption).foregroundColor(.secondary)
            }
            
            ForEach(Array(essayDetails.enumerated()), id: \.element.itemId) { index, detail in
                VStack(alignment: .leading, spacing: 12) {
                    Text("Q\(index + 1) (記述式)").font(.subheadline).fontWeight(.bold).foregroundColor(.secondary)
                    Text(detail.userAnswer?.displayString ?? "(回答なし)")
                        .font(.body).padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05)).cornerRadius(8)
                    Divider()
                    HStack(spacing: 12) {
                        gradeButton(detail: detail, isCorrect: false, label: "不正解", color: .red)
                        gradeButton(detail: detail, isCorrect: true, label: "正解 (承認)", color: .green)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private func gradeButton(detail: AnswerDetail, isCorrect: Bool, label: String, color: Color) -> some View {
        Button(action: { withAnimation { essayGrades[detail.itemId] = isCorrect } }) {
            HStack {
                Image(systemName: essayGrades[detail.itemId] == isCorrect ? (isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill") : "circle")
                Text(label)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(essayGrades[detail.itemId] == isCorrect ? color.opacity(0.1) : Color.clear)
            .foregroundColor(essayGrades[detail.itemId] == isCorrect ? color : .gray)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(essayGrades[detail.itemId] == isCorrect ? color : Color.gray.opacity(0.3), lineWidth: 1))
            .cornerRadius(8)
        }
    }
    
    private var submitButtonSection: some View {
        VStack(spacing: 12) {
            if log.status == "approved" {
                Button(action: startDM) {
                    HStack { Image(systemName: "envelope.fill"); Text("DMへ") }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.green).foregroundColor(.white).cornerRadius(12)
                }
                Text("✓ 採点済み - DMが可能です").font(.caption).foregroundColor(.green)
                
            } else if log.status == "rejected" || log.status == "rejected_auto" {
                Button(action: {}) {
                    HStack { Image(systemName: "checkmark.seal.fill"); Text("採点済み") }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.gray).foregroundColor(.white).cornerRadius(12)
                }
                .disabled(true)
                Text(log.status == "rejected_auto" ? "✓ 採点済み - 自動採点で不正解のためDMはできません" : "✓ 採点済み - 不正解のためDMはできません")
                    .font(.caption).foregroundColor(log.status == "rejected_auto" ? .orange : .red)
                
            } else {
                Button(action: submitGrading) {
                    HStack {
                        if profileViewModel.isJudging { ProgressView().tint(.white) }
                        else { Image(systemName: "checkmark.seal.fill"); Text("採点を確定する") }
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(allEssaysGraded ? Color.blue : Color.gray)
                    .foregroundColor(.white).cornerRadius(12)
                }
                .disabled(!allEssaysGraded || profileViewModel.isJudging)
                
                submitStatusText
            }
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var submitStatusText: some View {
        if allEssaysGraded {
            let allEssayApproved = essayGrades.values.allSatisfy { $0 }
            let hasAutoGradedIncorrect = autoGradedDetails.contains { !$0.isCorrect }
            
            if allEssayApproved {
                if hasAutoGradedIncorrect {
                    VStack(spacing: 4) {
                        Text("※ 自動採点で不正解があるため、DMはできません。").font(.caption).foregroundColor(.orange).fontWeight(.bold)
                        Text("（記述式の結果は「正解」として回答者に通知されます）").font(.caption2).foregroundColor(.secondary)
                    }
                } else {
                    Text("※ 「正解」として回答者に通知され、DMが可能になります。").font(.caption).foregroundColor(.green).fontWeight(.bold)
                }
            } else {
                Text("※ 「不正解」として通知されます。DMはできません。").font(.caption).foregroundColor(.red)
            }
        } else {
            Text("すべての記述式問題を判定してください").font(.caption).foregroundColor(.secondary)
        }
    }
    
    // MARK: - Logic
    
    private func initializeEssayGrades() {
        for detail in essayDetails {
            if detail.status == "approved" { essayGrades[detail.itemId] = true }
            else if detail.status == "rejected" { essayGrades[detail.itemId] = false }
        }
    }
    
    private func submitGrading() {
        Task {
            let success = await profileViewModel.submitEssayGrades(logId: log.logId, essayGrades: essayGrades)
            if success {
                let allEssayCorrect = essayGrades.values.allSatisfy { $0 == true }
                let hasAutoGradedIncorrect = autoGradedDetails.contains { !$0.isCorrect }
                if allEssayCorrect && !hasAutoGradedIncorrect {
                    refreshPendingList()
                    showGradingNotification = true
                } else { dismiss() }
            }
        }
    }
    
    private func refreshPendingList() {
        Task {
            if let userId = authViewModel.userSub {
                await profileViewModel.fetchMyGradedAnswers()
                await profileViewModel.fetchAnswerLogs(questionId: log.questionId)
                await dmViewModel.fetchThreads(userId: userId)
                await MainActor.run {
                    pendingDMManager.fetchPendingDMs(
                        myUserId: userId,
                        myAnswersLogs: profileViewModel.myGradedAnswers,
                        authorAnswersLogs: profileViewModel.answerLogs,
                        dmThreads: dmViewModel.threads
                    )
                }
            }
        }
    }
    
    private func startDM() {
        Task {
            if let thread = await dmViewModel.findDMThread(with: log.userId) {
                await MainActor.run { dismiss(); navManager.tabSelection = 2 }
            } else {
                await MainActor.run { showInitialDMView = true }
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
