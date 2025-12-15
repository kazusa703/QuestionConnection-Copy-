import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var navManager: NavigationManager

    // フィルタリング設定
    @State private var showingFilterSheet = false
    @State private var selectedPurpose = ""
    @State private var showingOnlyBookmarks = false
    
    // タグ検索用
    @State private var selectedTags: [String] = []
    @State private var tagInput: String = ""

    // キーワード検索
    @State private var searchTitle = ""
    @State private var searchQuestionId = ""
    
    // 並び替えオプション
    @State private var sortOption: SortOption = .newest
    
    // ランダム表示用の一時リスト
    @State private var randomQuestions: [Question] = []

    // ★★★ 復活: ローカルでの即時反映用リスト ★★★
    @State private var answeredQuestionIds: Set<String> = []

    enum SortOption {
        case newest
        case oldest
        case random
    }

    // フィルタリングロジック
    private var filteredPool: [Question] {
        var result = viewModel.questions
        
        // 自分の投稿を除外する処理
        if let currentUserId = authViewModel.userSub {
            result = result.filter { $0.authorId != currentUserId }
        }
        
        // ★★★ 修正: 両方のソースから回答済みを除外 ★★★
        // ローカルの answeredQuestionIds と profileViewModel.answeredQuestionIds の両方をチェック
        result = result.filter { question in
            !answeredQuestionIds.contains(question.questionId) &&
            !profileViewModel.answeredQuestionIds.contains(question.questionId)
        }
        
        // タイトル検索
        if !searchTitle.isEmpty {
            let keyword = searchTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            result = result.filter { question in
                question.title.localizedCaseInsensitiveContains(keyword)
            }
        }
        
        // 問題番号検索
        if !searchQuestionId.isEmpty {
            let keyword = searchQuestionId.trimmingCharacters(in: .whitespacesAndNewlines)
            result = result.filter { question in
                let code = question.shareCode ?? ""
                let codeMatch = code.localizedCaseInsensitiveContains(keyword)
                let idMatch = question.id.localizedCaseInsensitiveContains(keyword) || question.questionId.localizedCaseInsensitiveContains(keyword)
                return codeMatch || idMatch
            }
        }
        
        // ブロックユーザーの除外
        if authViewModel.isSignedIn {
            result = result.filter { question in
                !profileViewModel.isBlocked(userId: question.authorId)
            }
        }
        
        // 目的でフィルタ
        if !selectedPurpose.isEmpty {
            result = result.filter { $0.purpose == selectedPurpose }
        }
        
        // ブックマークでフィルタ
        if showingOnlyBookmarks && authViewModel.isSignedIn {
            result = result.filter { profileViewModel.isBookmarked(questionId: $0.id) }
        }
        
        // 指定タグでフィルタ (AND検索)
        if !selectedTags.isEmpty {
            result = result.filter { question in
                selectedTags.allSatisfy { selectedTag in
                    question.tags.contains { qTag in
                        qTag.localizedCaseInsensitiveContains(selectedTag)
                    }
                }
            }
        }
        
        return result
    }

    // 最終的な表示リスト
    private var displayQuestions: [Question] {
        switch sortOption {
        case .newest:
            return filteredPool.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filteredPool.sorted { $0.createdAt < $1.createdAt }
        case .random:
            return randomQuestions
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchTitle.isEmpty || !searchQuestionId.isEmpty || !selectedPurpose.isEmpty || !selectedTags.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // 広告バナー
            if !subscriptionManager.isPremium {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
            }
            
            // --- 適用中のフィルタ（バッジ）表示 ---
            if hasActiveFilters || showingOnlyBookmarks {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            searchTitle = ""
                            searchQuestionId = ""
                            selectedPurpose = ""
                            showingOnlyBookmarks = false
                            selectedTags.removeAll()
                        } label: {
                            Label("リセット", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        if !searchTitle.isEmpty {
                            FilterBadge(text: "📝 \(searchTitle)") {
                                searchTitle = ""
                            }
                        }
                        
                        if !searchQuestionId.isEmpty {
                            FilterBadge(text: "🔢 \(searchQuestionId)") {
                                searchQuestionId = ""
                            }
                        }
                        
                        if !selectedPurpose.isEmpty {
                            FilterBadge(text: "目的: \(selectedPurpose)")
                        }
                        if showingOnlyBookmarks {
                            FilterBadge(text: "ブックマーク中")
                        }
                        ForEach(selectedTags, id: \.self) { tag in
                            FilterBadge(text: "#\(tag)") {
                                removeTag(tag)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .bottom)
            }

            // --- 質問リスト ---
            if viewModel.isLoading && viewModel.questions.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if displayQuestions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("条件に一致する質問はありません")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(displayQuestions) { question in
                        ZStack(alignment: .leading) {
                            // 1. 中身
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(question.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    if let code = question.shareCode, !code.isEmpty {
                                        Text("#\(code)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                HStack(spacing: 6) {
                                    if let purpose = question.purpose, !purpose.isEmpty {
                                        Text(purpose)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                    
                                    if !question.tags.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(question.tags, id: \.self) { tag in
                                                    Text("#\(tag)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            
                            // 2. リンク (透明)
                            NavigationLink(destination: QuestionDetailView(question: question).environmentObject(profileViewModel)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                    }
                    
                    if sortOption == .random {
                        Section {
                            Button(action: reshuffleRandomQuestions) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("別の5件を表示する")
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetchQuestions()
                    if sortOption == .random { reshuffleRandomQuestions() }
                }
            }
        }
        .navigationTitle("掲示板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Menu {
                        Button { sortOption = .newest } label: {
                            Label("最新順", systemImage: sortOption == .newest ? "checkmark" : "")
                        }
                        Button { sortOption = .oldest } label: {
                            Label("古い順", systemImage: sortOption == .oldest ? "checkmark" : "")
                        }
                        Button {
                            sortOption = .random
                            reshuffleRandomQuestions()
                        } label: {
                            Label("ランダム", systemImage: sortOption == .random ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .padding(8)
                    }
                    
                    Button {
                        if authViewModel.isSignedIn {
                            showingOnlyBookmarks.toggle()
                        }
                    } label: {
                        Image(systemName: showingOnlyBookmarks ? "bookmark.fill" : "bookmark")
                            .foregroundColor(showingOnlyBookmarks ? .orange : .primary)
                            .padding(8)
                    }
                    
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .padding(8)
                    }
                }
            }
        }
        // フィルターシート
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("タイトルで検索")) {
                        TextField("タイトルを入力", text: $searchTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Section(header: Text("問題番号で検索")) {
                        TextField("問題番号を入力 (例: 12345)", text: $searchQuestionId)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.asciiCapable)
                    }
                    
                    Section(header: Text("目的で絞り込む")) {
                        Picker("目的", selection: $selectedPurpose) {
                            Text("指定なし").tag("")
                            ForEach(viewModel.availablePurposes, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                    }
                    
                    Section(header: Text("タグで絞り込む (AND検索)")) {
                        HStack {
                            TextField("タグを入力 (例: swift)", text: $tagInput)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .onSubmit { addTagFromInput() }
                            
                            Button(action: addTagFromInput) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        if !selectedTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(selectedTags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Button { removeTag(tag) } label: {
                                                Image(systemName: "xmark")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } else {
                            Text("タグを追加すると、そのすべてのタグを含む質問だけが表示されます。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            searchTitle = ""
                            searchQuestionId = ""
                            selectedPurpose = ""
                            selectedTags.removeAll()
                            tagInput = ""
                            showingFilterSheet = false
                        } label: {
                            Text("条件をリセットして閉じる")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .navigationTitle("検索・絞り込み")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") { showingFilterSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            await viewModel.fetchQuestions()
        }
        // タブ復帰時に再フェッチ
        .onChange(of: navManager.tabSelection) { _, newValue in
            if newValue == 0 {
                Task {
                    print("📌 BoardView: tabSelection->0 再フェッチ")
                    await viewModel.fetchQuestions()
                    if sortOption == .random { reshuffleRandomQuestions() }
                }
            }
        }
        // 掲示板へ通知受信: ViewModelとローカル状態の両方を更新
        .onReceive(NotificationCenter.default.publisher(for: .boardShouldRefresh)) { note in
            if let qid = note.object as? String {
                // ローカル状態に追加 (即時反映用)
                answeredQuestionIds.insert(qid)
                // ViewModelに追加 (全体反映用)
                profileViewModel.markQuestionAsAnswered(questionId: qid)
            }
            Task {
                print("📌 BoardView: boardShouldRefresh 受信 再フェッチ")
                await viewModel.fetchQuestions()
                if sortOption == .random { reshuffleRandomQuestions() }
            }
        }
        // ViewModelの回答済みIDが増えたらランダムリストも更新
        .onChange(of: profileViewModel.answeredQuestionIds) { _, _ in
            if sortOption == .random { reshuffleRandomQuestions() }
        }
    }

    private func reshuffleRandomQuestions() {
        let pool = filteredPool
        let shuffled = pool.shuffled()
        randomQuestions = Array(shuffled.prefix(5))
    }
    
    private func addTagFromInput() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        guard !selectedTags.contains(where: { $0.caseInsensitiveCompare(trimmedTag) == .orderedSame }) else {
            tagInput = ""
            return
        }
        guard selectedTags.count < 5 else { return }
        selectedTags.append(trimmedTag)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
}

// フィルタバッジ用のサブビュー
struct FilterBadge: View {
    let text: String
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(20)
    }
}
