import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var showingFilterSheet = false
    @State private var selectedPurpose = ""
    @State private var showingOnlyBookmarks = false
    
    @State private var selectedTags: [String] = []
    @State private var tagInput: String = ""

    @State private var searchText = ""
    
    @State private var sortOption: SortOption = .newest

    enum SortOption {
        case newest
        case oldest
    }

    private var filteredQuestions: [Question] {
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
        guard authViewModel.isSignedIn else {
            return filterByPurposeTagsAndSort(searchedQuestions)
        }
        
        let blockedFiltered = searchedQuestions.filter { question in
            !profileViewModel.isBlocked(userId: question.authorId)
        }
        
        // 3. 目的・タグフィルタとソートを適用
        return filterByPurposeTagsAndSort(blockedFiltered)
    }

    private func filterByPurposeTagsAndSort(_ questions: [Question]) -> [Question] {
        // 目的でフィルタ
        let purposeFiltered: [Question]
        if selectedPurpose.isEmpty {
            purposeFiltered = questions
        } else {
            purposeFiltered = questions.filter { question in
                question.purpose == selectedPurpose
            }
        }
        
        // ブックマークでフィルタ
        let bookmarkFiltered: [Question]
        if showingOnlyBookmarks && authViewModel.isSignedIn {
            bookmarkFiltered = purposeFiltered.filter { question in
                profileViewModel.isBookmarked(questionId: question.id)
            }
        } else {
            bookmarkFiltered = purposeFiltered
        }
        
        // タグでフィルタ（AND検索）
        let tagFiltered: [Question]
        if selectedTags.isEmpty {
            tagFiltered = bookmarkFiltered
        } else {
            tagFiltered = bookmarkFiltered.filter { question in
                selectedTags.allSatisfy { selectedTag in
                    question.tags.contains { $0.localizedCaseInsensitiveContains(selectedTag) }
                }
            }
        }
        
        // 並び替えを適用
        switch sortOption {
        case .newest:
            return tagFiltered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return tagFiltered.sorted { $0.createdAt < $1.createdAt }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
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
                }

                // --- 質問リスト ---
                if viewModel.isLoading && viewModel.questions.isEmpty {
                    ProgressView()
                } else if filteredQuestions.isEmpty && !viewModel.isLoading {
                    Text("指定された条件の質問はありません。")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(filteredQuestions) { question in
                        NavigationLink(destination: QuestionDetailView(question: question).environmentObject(profileViewModel)) {
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
                        }
                    }
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
                                    if sortOption == .newest {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { sortOption = .oldest }) {
                                HStack {
                                    Text("古い順")
                                    Spacer()
                                    if sortOption == .oldest {
                                        Image(systemName: "checkmark")
                                    }
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
            .refreshable { await fetchFilteredQuestions() }
        }
    }

    private func fetchFilteredQuestions() async {
        let purposeToFetch = selectedPurpose.isEmpty ? nil : selectedPurpose
        let bookmarkedByUserId: String? = (showingOnlyBookmarks && authViewModel.isSignedIn) ? authViewModel.userSub : nil
        await viewModel.fetchQuestions(purpose: purposeToFetch, bookmarkedBy: bookmarkedByUserId)
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
