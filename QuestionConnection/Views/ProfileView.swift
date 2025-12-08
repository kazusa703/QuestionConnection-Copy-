import SwiftUI

struct ProfileView: View {
    let userId: String
    let isMyProfile: Bool
    
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    
    @State private var isUserInfoExpanded = false
    @State private var isGradedAnswersExpanded = true
    
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    @State private var showReportAlert = false
    @State private var reportReason = ""
    @State private var reportDetail = ""
    
    @State private var showModelAnswerSheet = false
    
    @State private var selectedThread: DMThread? = nil
    @State private var showConversation = false

    @State private var selectedAnswerTab = "all"
    @State private var isCreatedQuestionsExpanded = false

    init(userId: String, isMyProfile: Bool, authViewModel: AuthViewModel) {
        self.userId = userId
        self.isMyProfile = isMyProfile
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        mainContent
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
                SetNicknameView()
                    .environmentObject(authViewModel)
                    .environmentObject(viewModel)
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
            .sheet(isPresented: $showConversation) {
                if let thread = selectedThread {
                    NavigationStack {
                        ConversationView(thread: thread, viewModel: dmViewModel)
                            .environmentObject(authViewModel)
                            .environmentObject(viewModel)
                    }
                }
            }
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
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                actionButtons
                
                Divider()
                
                if isMyProfile {
                    gradedAnswersSection
                    Divider()
                }
                
                createdQuestionsSection
                Divider()
                
                if isMyProfile {
                    userInfoSection
                    deleteAccountButton
                }
            }
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Components
    
    private var profileHeader: some View {
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
    }
    
    private var actionButtons: some View {
        Group {
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
        }
    }
    
    // MARK: - Graded Answers Section (Tabs & Badges)
    
    private var gradedAnswersSection: some View {
        DisclosureGroup(
            isExpanded: $isGradedAnswersExpanded,
            content: {
                VStack {
                    Picker("Filter", selection: $selectedAnswerTab) {
                        Text("すべて").tag("all")
                        Text("採点待ち").tag("pending")
                        Text("正解").tag("approved")
                        Text("不正解").tag("rejected")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                    
                    let filtered = filterAnswers(viewModel.myGradedAnswers)
                    
                    if filtered.isEmpty {
                        Text("該当する履歴はありません")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { log in
                                NavigationLink(destination: AnswerResultView(log: log)) {
                                    GradedAnswerRow(log: log)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 10)
                    }
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
                    
                    let pendingCount = viewModel.myGradedAnswers.filter { $0.status == "pending_review" }.count
                    if pendingCount > 0 {
                        Text("\(pendingCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    
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
    }
    
    private func filterAnswers(_ logs: [AnswerLogItem]) -> [AnswerLogItem] {
        switch selectedAnswerTab {
        case "pending": return logs.filter { $0.status == "pending_review" }
        case "approved": return logs.filter { $0.status == "approved" }
        case "rejected": return logs.filter { $0.status == "rejected" }
        default: return logs
        }
    }
    
    // MARK: - Created Questions Section (Tabs & Navigation Logic)
    
    // MARK: - Created Questions Section
        
        private var createdQuestionsSection: some View {
            Group {
                if isMyProfile {
                    // ★★★ 修正: 自分（作成者）の場合は、MyQuestionsDetailView へ遷移するボタンだけを表示 ★★★
                    // タブ機能やリスト表示は MyQuestionsDetailView に任せる
                    NavigationLink(destination: MyQuestionsDetailView(
                        questions: viewModel.myQuestions,
                        isLoadingMyQuestions: viewModel.isLoadingMyQuestions,
                        viewModel: viewModel
                    )) {
                        HStack {
                            Image(systemName: "questionmark.folder")
                                .foregroundColor(.accentColor)
                            
                            Text("自分が作成した質問")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 件数を表示
                            if !viewModel.myQuestions.isEmpty {
                                Text("\(viewModel.myQuestions.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                } else {
                    // 他人のプロフィールの場合は、既存の開閉リスト (DisclosureGroup) を維持
                    // (他人は採点や分析をする必要がないため、シンプルなリストでOK)
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
                                        // 他人が見る場合は常に回答画面へ
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
                                Text("作成した質問")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    private var userInfoSection: some View {
        DisclosureGroup(
            isExpanded: $isUserInfoExpanded,
            content: {
                AccountInfoSection()
                    .environmentObject(authViewModel)
                    .environmentObject(viewModel)
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
    }
    
    private var deleteAccountButton: some View {
        Button(action: { showDeleteAlert = true }) {
            Text("アカウント削除")
                .foregroundColor(.red)
                .padding()
        }
    }
}

// MARK: - Subviews

struct GradedAnswerRow: View {
    let log: AnswerLogItem
    
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
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
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
            
            VStack(alignment: .trailing) {
                if let pending = question.pendingCount, pending > 0 {
                    Text("未採点: \(pending)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                } else {
                    if let count = question.answerCount {
                        VStack {
                            Image(systemName: "person.2.fill")
                            Text("\(count)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
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
