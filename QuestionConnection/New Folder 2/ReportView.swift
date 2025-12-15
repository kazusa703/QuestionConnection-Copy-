import SwiftUI

struct ReportView: View {
    let targetType: ReportTargetType
    let targetId: String
    let targetName: String
    let onComplete: (Bool) -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason?
    @State private var reasonDetail: String = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: targetType.icon)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(targetType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(targetName)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                    }
                } header: {
                    Text("通報対象")
                }

                Section {
                    Text("不適切なコンテンツを報告することで、コミュニティの安全を守ることができます。虚偽の通報は利用規約違反となります。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button {
                            withAnimation {
                                selectedReason = reason
                            }
                        } label: {
                            HStack {
                                Image(systemName: reason.icon)
                                    .foregroundColor(reason.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reason.displayName)
                                        .foregroundColor(.primary)
                                        .fontWeight(selectedReason == reason ? .semibold : .regular)
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .transition(.scale)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("通報理由を選択してください")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if reasonDetail.isEmpty {
                            Text("具体的な内容があれば記入してください（任意）")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }

                        TextEditor(text: $reasonDetail)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("詳細（任意）")
                } footer: {
                    Text("\(reasonDetail.count)/500文字")
                        .foregroundColor(reasonDetail.count > 500 ? .red : .secondary)
                }
            }
            .navigationTitle("通報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        showConfirmation = true
                    }
                    .disabled(selectedReason == nil || isSubmitting || reasonDetail.count > 500)
                    .fontWeight(.semibold)
                }
            }
            .alert("通報を送信しますか？", isPresented: $showConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("送信", role: .destructive) {
                    Task {
                        await submitReport()
                    }
                }
            } message: {
                Text("この操作は取り消せません。")
            }
            .alert("通報を受け付けました", isPresented: $showSuccessAlert) {
                Button("OK") {
                    onComplete(true)
                    dismiss()
                }
            } message: {
                Text("ご報告ありがとうございます。内容を確認し、適切に対応いたします。")
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("送信中...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }

    // MARK: - 通報送信

    private func submitReport() async {
        guard let reason = selectedReason else { return }
        guard let reporterId = authViewModel.userSub else {
            errorMessage = "ログインが必要です"
            showErrorAlert = true
            return
        }

        isSubmitting = true

        let result = await ReportManager.shared.submitReport(
            reporterId: reporterId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            reasonDetail: reasonDetail,
            idToken: await authViewModel.getValidIdToken()
        )

        isSubmitting = false

        switch result {
        case .success:
            showSuccessAlert = true
        case .alreadyReported:
            errorMessage = "この内容は既に通報済みです"
            showErrorAlert = true
        case .failure(let message):
            errorMessage = message
            showErrorAlert = true
        }
    }
}

// MARK: - 通報対象タイプ

enum ReportTargetType: String {
    case question
    case user
    case message

    var displayName: String {
        switch self {
        case .question: return "質問"
        case .user: return "ユーザー"
        case .message: return "メッセージ"
        }
    }

    var icon: String {
        switch self {
        case .question: return "questionmark.circle"
        case .user: return "person.circle"
        case .message: return "message"
        }
    }
}

// MARK: - 通報理由

enum ReportReason: String, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case personalInfo = "personal_info"
    case violence = "violence"
    case sexual = "sexual"
    case fraud = "fraud"
    case other = "other"

    var displayName: String {
        switch self {
        case .spam: return "スパム・宣伝"
        case .harassment: return "嫌がらせ・誹謗中傷"
        case .inappropriate: return "不適切なコンテンツ"
        case .personalInfo: return "個人情報の公開"
        case .violence: return "暴力・脅迫"
        case .sexual: return "性的なコンテンツ"
        case .fraud: return "詐欺・なりすまし"
        case .other: return "その他"
        }
    }

    var description: String {
        switch self {
        case .spam: return "広告や無関係な投稿"
        case .harassment: return "特定の人への攻撃や中傷"
        case .inappropriate: return "不快または有害なコンテンツ"
        case .personalInfo: return "住所・電話番号などの個人情報"
        case .violence: return "暴力的な表現や脅し"
        case .sexual: return "性的な表現や画像"
        case .fraud: return "詐欺行為や他人へのなりすまし"
        case .other: return "上記に該当しない問題"
        }
    }

    var icon: String {
        switch self {
        case .spam: return "megaphone"
        case .harassment: return "exclamationmark.bubble"
        case .inappropriate: return "hand.raised"
        case .personalInfo: return "person.badge.key"
        case .violence: return "bolt.shield"
        case .sexual: return "eye.slash"
        case .fraud: return "person.crop.circle.badge.exclamationmark"
        case .other: return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .spam: return .orange
        case .harassment: return .red
        case .inappropriate: return .purple
        case .personalInfo: return .blue
        case .violence: return .red
        case .sexual: return .pink
        case .fraud: return .yellow
        case .other: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ReportView(
        targetType: .question,
        targetId: "test-123",
        targetName: "テストの質問タイトル"
    ) { success in
        print("Report completed: \(success)")
    }
    .environmentObject(AuthViewModel())
}
