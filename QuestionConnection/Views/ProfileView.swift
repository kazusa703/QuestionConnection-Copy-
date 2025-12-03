import SwiftUI

struct ProfileView: View {
    let userId: String
    let isMyProfile: Bool
    
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    
    // 折りたたみ用の状態変数
    @State private var isCreatedQuestionsExpanded = false
    @State private var isUserInfoExpanded = false
    @State private var isGradedAnswersExpanded = true
    
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    @State private var showReportAlert = false
    @State private var reportReason = ""
    @State private var reportDetail = ""
    
    // 模範解答シートの制御
    @State private var showModelAnswerSheet = false
    
    // DM遷移トリガー
    @State private var navigateToDM = false
    @State private var selectedDMThreadId: String? = nil
    @State private var selectedRecipientId: String = ""

    init(userId: String, isMyProfile: Bool, authViewModel: AuthViewModel) {
        self.userId = userId
        self.isMyProfile = isMyProfile
        
        // ★ 修正: 複雑な式を分割
        let profileVM = ProfileViewModel(authViewModel: authViewModel)
        _viewModel = StateObject(wrappedValue: profileVM)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. プロフィールヘッダー (画像と名前)
                VStack(spacing: 15) {
                    if let imageUrl = viewModel.userProfileImages[userId], let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    
                    Text(viewModel.userNicknames[userId] ?? "読み込み中...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let stats = viewModel.userStats {
                        HStack(spacing: 20) {
                            StatView(label: "回答数", value: "\(stats.totalAnswers)")
                            StatView(label: "正解数", value: "\(stats.correctAnswers)")
                            StatView(label: "正答率", value: String(format: "%.1f%%", stats.accuracy * 100))
                        }
                        .padding(.top, 5)
                    }
                }
                .padding()
                
                // 2. ボタンエリア (設定/編集 or ブロック/報告)
                if isMyProfile {
                    HStack {
                        Button(action: { showEditProfile = true }) {
                            Label("編集", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { showSettings = true }) {
                            Label("設定", systemImage: "gearshape")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    HStack {
                        if viewModel.isBlocked(userId: userId) {
                            Button("ブロック解除") {
                                Task { await viewModel.removeBlock(blockedUserId: userId) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.gray)
                        } else {
                            Button("ブロック") {
                                Task { await viewModel.addBlock(blockedUserId: userId) }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        
                        Button("通報") {
                            showReportAlert = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // 3. 記述式問題の結果
                if isMyProfile {
                    DisclosureGroup(
                        isExpanded: $isGradedAnswersExpanded,
                        content: {
                            if viewModel.myGradedAnswers.isEmpty {
                                Text("記述式問題の回答履歴はありません")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.myGradedAnswers) { log in
                                        GradedAnswerRow(log: log, onAction: { action in
                                            handleGradedAnswerAction(action, log: log)
                                        })
                                    }
                                }
                                .padding(.top, 10)
                            }
                        },
                        label: {
                            HStack {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .foregroundColor(.accentColor)
                                Text("記述式問題の結果")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(viewModel.myGradedAnswers.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .padding(.vertical, 8)
                        }
                    )
                    .padding(.horizontal)
                    .accentColor(.primary)
                    
                    Divider()
                }
                
                // 4. 自分が作成した質問
                DisclosureGroup(
                    isExpanded: $isCreatedQuestionsExpanded,
                    content: {
                        if viewModel.isLoadingMyQuestions {
                            ProgressView().padding()
                        } else if viewModel.myQuestions.isEmpty {
                            Text("まだ質問を作成していません")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack {
                                ForEach(viewModel.myQuestions) { question in
                                    NavigationLink(destination: QuestionDetailView(question: question)) {
                                        QuestionRowView(question: question)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    Divider()
                                }
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "questionmark.folder")
                                .foregroundColor(.accentColor)
                            Text("自分が作成した質問")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                )
                .padding(.horizontal)
                
                Divider()
                
                // 5. ユーザー情報
                if isMyProfile {
                    DisclosureGroup(
                        isExpanded: $isUserInfoExpanded,
                        content: {
                            AccountInfoSection(authViewModel: authViewModel, profileViewModel: viewModel)
                                .padding(.top)
                        },
                        label: {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(.accentColor)
                                Text("ユーザー情報")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    )
                    .padding(.horizontal)
                    
                    Button(action: { showDeleteAlert = true }) {
                        Text("アカウント削除")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchNicknameAndImage(userId: userId)
                await viewModel.fetchUserStats(userId: userId)
                await viewModel.fetchMyQuestions(authorId: userId)
                if isMyProfile {
                    await viewModel.fetchMyGradedAnswers()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authViewModel)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showEditProfile) {
            SetNicknameView(authViewModel: authViewModel, profileViewModel: viewModel)
        }
        .sheet(isPresented: $showModelAnswerSheet) {
            if let question = viewModel.selectedQuestionForModelAnswer {
                ModelAnswerView(question: question)
            } else {
                VStack {
                    ProgressView("読み込み中...")
                    Button("閉じる") { showModelAnswerSheet = false }.padding()
                }
            }
        }
        .background(
            NavigationLink(
                destination: ConversationView(
                    threadId: selectedDMThreadId ?? "",
                    recipientId: selectedRecipientId
                ),
                isActive: $navigateToDM
            ) {
                EmptyView()
            }
        )
        .alert("通報", isPresented: $showReportAlert) {
            TextField("理由", text: $reportReason)
            TextField("詳細", text: $reportDetail)
            Button("送信") {
                Task {
                    _ = await viewModel.reportContent(targetId: userId, targetType: "user", reason: reportReason, detail: reportDetail)
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .alert("アカウント削除", isPresented: $showDeleteAlert) {
            Button("削除する", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        authViewModel.signOut()
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("本当に削除しますか？この操作は取り消せません。")
        }
    }
    
    // アクションハンドリング
    enum AnswerAction {
        case openDM
        case showModelAnswer
    }
    
    private func handleGradedAnswerAction(_ action: AnswerAction, log: AnswerLogItem) {
        switch action {
        case .openDM:
            guard let authorId = log.authorId else { return }
            
            Task {
                let existingThread = await dmViewModel.threads.first { thread in
                    Set(thread.participantIds).contains(authorId)
                }
                
                await MainActor.run {
                    self.selectedRecipientId = authorId
                    if let thread = existingThread {
                        self.selectedDMThreadId = thread.threadId
                    } else {
                        self.selectedDMThreadId = nil
                    }
                    self.navigateToDM = true
                }
            }
            
        case .showModelAnswer:
            Task {
                await viewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
                self.showModelAnswerSheet = true
            }
        }
    }
}

// 記述式問題の結果行ビュー
struct GradedAnswerRow: View {
    let log: AnswerLogItem
    let onAction: (ProfileView.AnswerAction) -> Void
    
    var statusText: String {
        switch log.status {
        case "approved": return "正解"
        case "rejected": return "不正解"
        case "pending_review": return "採点待ち"
        default: return "完了"
        }
    }
    
    var statusColor: Color {
        switch log.status {
        case "approved": return .green
        case "rejected": return .red
        case "pending_review": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.questionTitle ?? "質問ID: \(log.questionId.prefix(8))...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(log.updatedAt.prefix(10))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(4)
            
            if log.status == "approved" {
                Button(action: { onAction(.openDM) }) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            } else if log.status == "rejected" {
                Button(action: { onAction(.showModelAnswer) }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct QuestionRowView: View {
    let question: Question
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(question.title)
                    .font(.headline)
                Text(question.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let count = question.answerCount {
                VStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(count)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct StatView: View {
    let label: String
    let value: String
    var body: some View {
        VStack {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
}
