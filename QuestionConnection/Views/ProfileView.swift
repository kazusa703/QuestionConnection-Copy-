import SwiftUI
import PhotosUI

struct ProfileView: View {
    let userId: String
    let isMyProfile: Bool
    
    // 親から受け取るViewModel
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    
    // ★ 削除: isGradedAnswersExpanded, selectedAnswerTab は新しい画面に移譲したため不要
    // @State private var isGradedAnswersExpanded = true
    // @State private var selectedAnswerTab = "all"
    
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showReportAlert = false
    @State private var reportReason = ""
    @State private var reportDetail = ""
    
    @State private var showModelAnswerSheet = false
    
    @State private var selectedThread: DMThread? = nil
    @State private var showConversation = false

    @State private var isCreatedQuestionsExpanded = false
    
    // 画像選択用
    @State private var selectedItem: PhotosPickerItem? = nil
    
    // 画像キャッシュ回避用のID
    @State private var cacheBuster = UUID().uuidString

    init(userId: String, isMyProfile: Bool) {
        self.userId = userId
        self.isMyProfile = isMyProfile
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
            }
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Components
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // アイコン
            if isMyProfile {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    profileImageContent
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .offset(x: 5, y: 5)
                        }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await viewModel.uploadProfileImage(userId: userId, image: uiImage)
                            cacheBuster = UUID().uuidString
                        }
                    }
                }
            } else {
                profileImageContent
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
        .alert("プロフィール画像", isPresented: $viewModel.showProfileImageAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.profileImageAlertMessage ?? "")
        }
    }
    
    private var profileImageContent: some View {
        Group {
            if viewModel.isUploadingProfileImage {
                ProgressView()
                    .frame(width: 100, height: 100)
            } else if let imageUrl = viewModel.userProfileImages[userId],
                      let url = URL(string: "\(imageUrl)?v=\(cacheBuster)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
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
    
    // MARK: - Graded Answers Section (修正版)
    
    private var gradedAnswersSection: some View {
        // ★ 修正: DisclosureGroup をやめて NavigationLink に変更
        NavigationLink(destination: GradedAnswersDetailView(viewModel: viewModel)) {
            HStack {
                Image(systemName: "pencil.and.list.clipboard")
                    .foregroundColor(.accentColor)
                
                Text("記述式問題の結果")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // バッジ（採点待ち数）
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
                
                // バッジ（総数）
                if !viewModel.myGradedAnswers.isEmpty {
                    Text("\(viewModel.myGradedAnswers.count)")
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
        .padding(.horizontal)
    }
    
    // ★ 削除: filterAnswers メソッドも新しいViewに移動したので不要
    
    // MARK: - Created Questions Section
    
    private var createdQuestionsSection: some View {
        Group {
            if isMyProfile {
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
                            Text("作成した質問")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                )
                .padding(.horizontal) // ここだけ調整
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - New Subview for Graded Answers (新規作成)

struct GradedAnswersDetailView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedAnswerTab = "all"
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedAnswerTab) {
                Text("すべて").tag("all")
                Text("採点待ち").tag("pending")
                Text("正解").tag("approved")
                Text("不正解").tag("rejected")
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemBackground))
            
            List {
                let filtered = filterAnswers(viewModel.myGradedAnswers)
                
                if filtered.isEmpty {
                    Text("該当する履歴はありません")
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                        .padding(.top, 20)
                } else {
                    ForEach(filtered) { log in
                        NavigationLink(destination: AnswerResultView(log: log)) {
                            GradedAnswerRow(log: log)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("記述式問題の結果")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func filterAnswers(_ logs: [AnswerLogItem]) -> [AnswerLogItem] {
        switch selectedAnswerTab {
        case "pending": return logs.filter { $0.status == "pending_review" }
        case "approved": return logs.filter { $0.status == "approved" }
        case "rejected": return logs.filter { $0.status == "rejected" }
        default: return logs
        }
    }
}

// MARK: - Existing Subviews

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
        }
        .padding(.vertical, 4)
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
        }
        .padding(.vertical, 4)
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
