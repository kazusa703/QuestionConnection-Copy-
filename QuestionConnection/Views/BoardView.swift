import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // ★ 追加: 課金管理
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showingFilterSheet = false
    @State private var selectedPurpose = ""
    @State private var showingOnlyBookmarks = false
    
    @State private var selectedTags: [String] = []
    @State private var tagInput: String = ""

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

    // フィルタリングのみを行う（ソートはしない）プロパティ
    private var filteredPool: [Question] {
        // 1. 検索フィルタ
        let searchedQuestions: [Question]
        if searchText.isEmpty {
            searchedQuestions = viewModel.questions
        } else {
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            searchedQuestions = viewModel.questions.filter { question in
                let titleMatch = question.title.localizedCaseInsensitiveContains(keyword)
                let tagMatch = question.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
                let codeMatch = (question.shareCode ?? "").localizedCaseInsensitiveContains(keyword)
                return titleMatch || tagMatch || codeMatch
            }
        }
        
        // 2. ブロックフィルタ
        let blockedFiltered: [Question]
        if authViewModel.isSignedIn {
            blockedFiltered = searchedQuestions.filter { question in
                !profileViewModel.isBlocked(userId: question.authorId)
            }
        } else {
            blockedFiltered = searchedQuestions
        }
        
        // 3. 目的でフィルタ
        let purposeFiltered: [Question]
        if selectedPurpose.isEmpty {
            purposeFiltered = blockedFiltered
        } else {
            purposeFiltered = blockedFiltered.filter { question in
                question.purpose == selectedPurpose
            }
        }
        
        // 4. ブックマークでフィルタ
        let bookmarkFiltered: [Question]
        if showingOnlyBookmarks && authViewModel.isSignedIn {
            bookmarkFiltered = purposeFiltered.filter { question in
                profileViewModel.isBookmarked(questionId: question.id)
            }
        } else {
            bookmarkFiltered = purposeFiltered
        }
        
        // 5. タグでフィルタ（AND検索）
        if selectedTags.isEmpty {
            return bookmarkFiltered
        } else {
            return bookmarkFiltered.filter { question in
                selectedTags.allSatisfy { selectedTag in
                    question.tags.contains { $0.localizedCaseInsensitiveContains(selectedTag) }
                }
            }
        }
    }

    // 最終的な表示リスト（ソート または ランダム抽出）
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
        NavigationStack {
            VStack(spacing: 0) { // ★ spacing: 0 にして隙間をなくす
                // ★★★ 追加: バナー広告 ★★★
                if !subscriptionManager.isPremium {
                    AdBannerView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                }
                
                // --- 適用中のフィルタ表示 ---
                if !selectedPurpose.isEmpty || showingOnlyBookmarks || !selectedTags.isEmpty {
                    HStack {
                        let descriptions = buildFilterDescriptions()
                        
                        Text(descriptions.joined(separator: " | "))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            selectedPurpose = ""
                            showingOnlyBookmarks = false
                            selectedTags.removeAll()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8) // 少し余白
                }

                // --- 質問リスト ---
                if viewModel.isLoading && viewModel.questions.isEmpty {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if displayQuestions.isEmpty && !viewModel.isLoading {
                    Text("指定された条件の質問はありません。")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(displayQuestions) { question in
                            // ★★★ 修正: ZStackを使って矢印(>)を消すテクニック ★★★
                            ZStack(alignment: .leading) {
                                // 1. 中身（見た目）
                                VStack(alignment: .leading) {
                                    Text(question.title)
                                        .font(.headline)
                                    HStack(spacing: 6) {
                                        if let purpose = question.purpose, !purpose.isEmpty {
                                            Text(purpose)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                        
                                        Text("タグ: \(question.tags.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // 2. 透明なリンク（機能）
                                NavigationLink(destination: QuestionDetailView(question: question).environmentObject(profileViewModel)) {
                                    EmptyView()
                                }
                                .opacity(0) // 透明にする
                            }
                        }
                        
                        // ランダムモード時のみ表示する「リシャッフルボタン」
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
            // ツールバー
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 1. 並び替えメニュー
                        Menu {
                            Button(action: { sortOption = .newest }) {
                                HStack {
                                    Text("最新順")
                                    Spacer()
                                    if sortOption == .newest { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { sortOption = .oldest }) {
                                HStack {
                                    Text("古い順")
                                    Spacer()
                                    if sortOption == .oldest { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: {
                                sortOption = .random
                                reshuffleRandomQuestions()
                            }) {
                                HStack {
                                    Text("ランダム")
                                    Spacer()
                                    if sortOption == .random { Image(systemName: "checkmark") }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        
                        // 2. ブックマークボタン
                        Button(action: {
                            if authViewModel.isSignedIn {
                                showingOnlyBookmarks.toggle()
                            }
                        }) {
                            Image(systemName: showingOnlyBookmarks ? "bookmark.fill" : "bookmark")
                                .foregroundColor(showingOnlyBookmarks ? .orange : .gray)
                        }
                        
                        // 3. 絞り込みボタン
                        Button {
                            showingFilterSheet = true
                        } label: {
                            Image(systemName: (!selectedPurpose.isEmpty || !selectedTags.isEmpty) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            
            // 統合絞り込みシート
            .sheet(isPresented: $showingFilterSheet) {
                NavigationStack {
                    Form {
                        // 検索バー
                        Section(header: Text("検索")) {
                            TextField("タイトル・問題番号で検索", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // 目的で絞り込み
                        Section(header: Text("目的で絞り込む")) {
                            Picker("目的を選択", selection: $selectedPurpose) {
                                Text("選択なし").tag("")
                                ForEach(viewModel.availablePurposes, id: \.self) { p in
                                    Text(p).tag(p)
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }
                        
                        // タグで検索
                        Section(header: Text("タグで検索")) {
                            HStack {
                                TextField("タグを入力", text: $tagInput)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: addTagFromInput) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                }
                                .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        
                        if !selectedTags.isEmpty {
                            Section(header: Text("選択中のタグ（\(selectedTags.count)/5）")) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedTags, id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                    .font(.caption)
                                                Button(action: { removeTag(tag) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.caption)
                                                }
                                            }
                                            .padding(6)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            
                            Section {
                                Button(role: .destructive) {
                                    selectedTags.removeAll()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("タグ検索をリセット")
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // リセットボタン
                        Section {
                            Button(role: .destructive) {
                                selectedPurpose = ""
                                showingOnlyBookmarks = false
                                selectedTags.removeAll()
                                searchText = ""
                                showingFilterSheet = false
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("すべてをリセット")
                                    Spacer()
                                }
                            }
                        }
                    }
                    .navigationTitle("絞り込み")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完了") {
                                showingFilterSheet = false
                            }
                        }
                    }
                }
            }
            
            .task {
                viewModel.setAuthViewModel(authViewModel)
                await fetchFilteredQuestions()
            }
            .refreshable {
                await fetchFilteredQuestions()
                if sortOption == .random {
                    reshuffleRandomQuestions()
                }
            }
            .onChange(of: searchText) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
            .onChange(of: selectedPurpose) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
            .onChange(of: showingOnlyBookmarks) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
            .onChange(of: selectedTags) { _ in if sortOption == .random { reshuffleRandomQuestions() } }
        }
    }

    private func fetchFilteredQuestions() async {
        let purposeToFetch = selectedPurpose.isEmpty ? nil : selectedPurpose
        let bookmarkedByUserId: String? = (showingOnlyBookmarks && authViewModel.isSignedIn) ? authViewModel.userSub : nil
        await viewModel.fetchQuestions(purpose: purposeToFetch, bookmarkedBy: bookmarkedByUserId)
    }
    
    private func reshuffleRandomQuestions() {
        let pool = filteredPool
        let shuffled = pool.shuffled()
        randomQuestions = Array(shuffled.prefix(5))
    }
    
    private func addTagFromInput() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        guard !selectedTags.contains(trimmedTag) else { return }
        guard selectedTags.count < 5 else { return }
        
        selectedTags.append(trimmedTag)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }
    
    private func buildFilterDescriptions() -> [String] {
        var descriptions: [String] = []
        if !selectedPurpose.isEmpty {
            descriptions.append("目的: \(selectedPurpose)")
        }
        if showingOnlyBookmarks {
            descriptions.append("ブックマーク")
        }
        if !selectedTags.isEmpty {
            descriptions.append("タグ: \(selectedTags.joined(separator: ", "))")
        }
        return descriptions
    }
}
