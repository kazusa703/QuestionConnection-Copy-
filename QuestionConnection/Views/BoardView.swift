import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    // フィルタリング設定
    @State private var showingFilterSheet = false
    @State private var selectedPurpose = ""
    @State private var showingOnlyBookmarks = false
    
    // タグ検索用
    @State private var selectedTags: [String] = []
    @State private var tagInput: String = ""

    // メインの検索テキスト（フィルターシート内に移動）
    @State private var searchText = ""
    
    // 並び替えオプション
    @State private var sortOption: SortOption = .newest
    
    // ランダム表示用の一時リスト
    @State private var randomQuestions: [Question] = []

    enum SortOption {
        case newest
        case oldest
        case random
    }

    // フィルタリングロジック
    private var filteredPool: [Question] {
        var result = viewModel.questions
        
        // 1. テキスト検索 (タイトル / タグ / 問題番号)
        if !searchText.isEmpty {
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            result = result.filter { question in
                let titleMatch = question.title.localizedCaseInsensitiveContains(keyword)
                let tagMatch = question.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
                let code = question.shareCode ?? ""
                let codeMatch = code.localizedCaseInsensitiveContains(keyword)
                let idMatch = question.id.localizedCaseInsensitiveContains(keyword) || question.questionId.localizedCaseInsensitiveContains(keyword)
                
                return titleMatch || tagMatch || codeMatch || idMatch
            }
        }
        
        // 2. ブロックユーザーの除外
        if authViewModel.isSignedIn {
            result = result.filter { question in
                !profileViewModel.isBlocked(userId: question.authorId)
            }
        }
        
        // 3. 目的でフィルタ
        if !selectedPurpose.isEmpty {
            result = result.filter { $0.purpose == selectedPurpose }
        }
        
        // 4. ブックマークでフィルタ
        if showingOnlyBookmarks && authViewModel.isSignedIn {
            result = result.filter { profileViewModel.isBookmarked(questionId: $0.id) }
        }
        
        // 5. 指定タグでフィルタ (AND検索)
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

    var body: some View {
        VStack(spacing: 0) {
            // 広告バナー
            if !subscriptionManager.isPremium {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
            }
            
            // --- 適用中のフィルタ（バッジ）表示 ---
            if !searchText.isEmpty || !selectedPurpose.isEmpty || showingOnlyBookmarks || !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            searchText = ""
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
                        
                        if !searchText.isEmpty {
                            FilterBadge(text: "🔍 \(searchText)") {
                                searchText = ""
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
                Divider()
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
                        Image(systemName: (!searchText.isEmpty || !selectedPurpose.isEmpty || !selectedTags.isEmpty) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .padding(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                Form {
                    // ★★★ 追加: 検索欄をフィルターシートの最上部に移動 ★★★
                    Section(header: Text("キーワード検索")) {
                        TextField("タイトル・タグ・問題番号で検索", text: $searchText)
                            .textFieldStyle(.roundedBorder)
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
                                .onSubmit {
                                    addTagFromInput()
                                }
                            
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
                                            
                                            Button {
                                                removeTag(tag)
                                            } label: {
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
                            searchText = ""
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
                        Button("完了") {
                            showingFilterSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            await viewModel.fetchQuestions()
        }
        .refreshable {
            await viewModel.fetchQuestions()
            if sortOption == .random {
                reshuffleRandomQuestions()
            }
        }
        .onChange(of: searchText) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
        .onChange(of: selectedPurpose) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
        .onChange(of: showingOnlyBookmarks) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
        .onChange(of: selectedTags) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
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
