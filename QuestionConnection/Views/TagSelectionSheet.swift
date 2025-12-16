import SwiftUI

struct TagSelectionSheet: View {
    @Binding var selectedTags: [String]
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = TagViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    // ★★★ よく使うタグ（UserDefaultsから読み込み） ★★★
    @AppStorage("favoriteTagsData") private var favoriteTagsData: Data = Data()
    @State private var favoriteTags: [String] = []
    
    // ★★★ 自由入力追加用のアラート管理 ★★★
    @State private var showingAddFavoriteAlert = false
    @State private var newFavoriteTagName = ""
    
    let maxTags = 5
    let maxFavoriteTags = 20
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 1. 選択中のタグ
                    selectedTagsSection
                    
                    Divider()
                    
                    // 2. 入力欄
                    inputSection
                    
                    // 3. 入力中の結果
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        inputResultsSection
                    }
                    
                    // 4. 入力していない場合のセクション
                    if inputText.isEmpty {
                        favoriteTagsSection  // 手動追加ボタン付き
                        popularTagsSection   // 変化なし
                        recentTagsSection    // 変化なし
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("タグを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            // ★★★ 自由追加用のアラート ★★★
            .alert("よく使うタグを追加", isPresented: $showingAddFavoriteAlert) {
                TextField("タグ名", text: $newFavoriteTagName)
                Button("キャンセル", role: .cancel) { }
                Button("追加") {
                    let trimmed = newFavoriteTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        addFavoriteTag(trimmed)
                    }
                }
            } message: {
                Text("追加したいタグを入力してください")
            }
        }
        .onAppear {
            loadFavoriteTags()
        }
        .task {
            await viewModel.fetchPopularTags()
            await viewModel.fetchRecentTags()
        }
    }
    
    // MARK: - 選択中のタグ
    
    @ViewBuilder
    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("選択中のタグ (\(selectedTags.count)/\(maxTags))")
                    .font(.headline)
            }
            
            if selectedTags.isEmpty {
                Text("タグが選択されていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                TagFlowLayout(spacing: 8) {
                    ForEach(selectedTags, id: \.self) { tag in
                        selectedTagChip(tag: tag)
                            .contextMenu {
                                favoriteActionMenu(tag: tag)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - 入力欄
    
    @ViewBuilder
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タグを検索・追加")
                .font(.headline)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("タグを入力...", text: $inputText)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: inputText) { _, newValue in
                        viewModel.searchTags(query: newValue)
                    }
                    .onSubmit {
                        addCustomTag()
                    }
                
                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 入力中の結果
    
    @ViewBuilder
    private var inputResultsSection: some View {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📊 候補")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.searchResults) { tag in
                        suggestionRow(tag: tag)
                            .contextMenu {
                                favoriteActionMenu(tag: tag.displayName)
                            }
                    }
                }
            }
            
            let existsInResults = viewModel.searchResults.contains {
                $0.displayName.lowercased() == trimmed.lowercased()
            }
            let alreadySelected = selectedTags.contains {
                $0.lowercased() == trimmed.lowercased()
            }
            
            if !existsInResults && !alreadySelected && selectedTags.count < maxTags {
                Button {
                    addCustomTag()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("「\(trimmed)」を新しいタグとして追加")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    favoriteActionMenu(tag: trimmed)
                }
            }
            
            if alreadySelected {
                HStack {
                    Image(systemName: "info.circle")
                    Text("「\(trimmed)」は既に選択されています")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - ★★★ よく使うタグ（手動追加・削除） ★★★
    
    @ViewBuilder
    private var favoriteTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("よく使うタグ")
                    .font(.headline)
                
                // ★★★ 追加: 自由入力用のプラスボタン ★★★
                Button {
                    newFavoriteTagName = ""
                    showingAddFavoriteAlert = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .padding(.leading, 4)
                
                Spacer()
                
                if !favoriteTags.isEmpty {
                    Button {
                        clearFavoriteTags()
                    } label: {
                        Text("クリア")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if favoriteTags.isEmpty {
                Text("＋ボタンまたは長押しで追加できます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                TagFlowLayout(spacing: 8) {
                    ForEach(favoriteTags, id: \.self) { tag in
                        favoriteTagChip(tag: tag)
                    }
                }
            }
        }
    }
    
    // MARK: - 人気タグ
    
    @ViewBuilder
    private var popularTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("人気のタグ")
                    .font(.headline)
            }
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.popularTags.isEmpty {
                Text("人気のタグはまだありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                TagFlowLayout(spacing: 8) {
                    ForEach(viewModel.popularTags) { tag in
                        tagChip(tag: tag)
                            .contextMenu {
                                favoriteActionMenu(tag: tag.displayName)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - 最近のタグ
    
    @ViewBuilder
    private var recentTagsSection: some View {
        let filteredRecentTags = viewModel.recentTags.filter { tag in
            !viewModel.popularTags.contains { $0.tagName == tag.tagName }
        }
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("最近使われたタグ")
                    .font(.headline)
            }
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if filteredRecentTags.isEmpty && viewModel.recentTags.isEmpty {
                Text("最近使われたタグはまだありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if filteredRecentTags.isEmpty {
                Text("人気のタグと同じです")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                TagFlowLayout(spacing: 8) {
                    ForEach(filteredRecentTags) { tag in
                        tagChip(tag: tag)
                            .contextMenu {
                                favoriteActionMenu(tag: tag.displayName)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - コンテキストメニュー
    
    @ViewBuilder
    private func favoriteActionMenu(tag: String) -> some View {
        if favoriteTags.contains(where: { $0.lowercased() == tag.lowercased() }) {
            Button(role: .destructive) {
                removeFavoriteTag(tag)
            } label: {
                Label("よく使うタグから削除", systemImage: "star.slash")
            }
        } else {
            Button {
                addFavoriteTag(tag)
            } label: {
                Label("よく使うタグに追加", systemImage: "star")
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func tagChip(tag: TagSuggestion) -> some View {
        let isSelected = isTagSelected(tag.displayName)
        let isFavorite = favoriteTags.contains { $0.lowercased() == tag.displayName.lowercased() }
        
        Button {
            toggleTag(tag.displayName)
        } label: {
            HStack(spacing: 4) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .yellow)
                }
                
                Text("#\(tag.displayName)")
                    .font(.subheadline)
                
                Text("\(tag.usageCount)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func favoriteTagChip(tag: String) -> some View {
        let isSelected = isTagSelected(tag)
        
        Button {
            toggleTag(tag)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .yellow)
                
                Text("#\(tag)")
                    .font(.subheadline)
                
                // 削除ボタン
                Button {
                    removeFavoriteTag(tag)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.yellow.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func selectedTagChip(tag: String) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)
            
            Button {
                removeTag(tag)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private func suggestionRow(tag: TagSuggestion) -> some View {
        let isSelected = isTagSelected(tag.displayName)
        let isFavorite = favoriteTags.contains { $0.lowercased() == tag.displayName.lowercased() }
        
        Button {
            toggleTag(tag.displayName)
            inputText = ""
            viewModel.searchResults = []
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                HStack(spacing: 4) {
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    Text("#\(tag.displayName)")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(tag.usageCount)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Functions
    
    private func isTagSelected(_ tagName: String) -> Bool {
        selectedTags.contains { $0.lowercased() == tagName.lowercased() }
    }
    
    private func toggleTag(_ tagName: String) {
        if isTagSelected(tagName) {
            removeTag(tagName)
        } else {
            addTag(tagName)
        }
    }
    
    private func addTag(_ tagName: String) {
        guard selectedTags.count < maxTags else { return }
        guard !isTagSelected(tagName) else { return }
        selectedTags.append(tagName)
    }
    
    private func removeTag(_ tagName: String) {
        selectedTags.removeAll { $0.lowercased() == tagName.lowercased() }
    }
    
    private func addCustomTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isTagSelected(trimmed) else {
            inputText = ""
            return
        }
        guard selectedTags.count < maxTags else { return }
        
        selectedTags.append(trimmed)
        inputText = ""
        viewModel.searchResults = []
    }
    
    // MARK: - よく使うタグの管理（手動）
    
    private func loadFavoriteTags() {
        if let decoded = try? JSONDecoder().decode([String].self, from: favoriteTagsData) {
            favoriteTags = decoded
        }
    }
    
    private func saveFavoriteTags() {
        if let encoded = try? JSONEncoder().encode(favoriteTags) {
            favoriteTagsData = encoded
        }
    }
    
    // 手動追加用
    private func addFavoriteTag(_ tag: String) {
        // 重複チェック
        if favoriteTags.contains(where: { $0.lowercased() == tag.lowercased() }) {
            return
        }
        // 先頭に追加
        favoriteTags.insert(tag, at: 0)
        
        // 最大数制限
        if favoriteTags.count > maxFavoriteTags {
            favoriteTags = Array(favoriteTags.prefix(maxFavoriteTags))
        }
        saveFavoriteTags()
    }
    
    private func removeFavoriteTag(_ tag: String) {
        favoriteTags.removeAll { $0.lowercased() == tag.lowercased() }
        saveFavoriteTags()
    }
    
    private func clearFavoriteTags() {
        favoriteTags = []
        saveFavoriteTags()
    }
}

// 修正点: ここにあった struct TagFlowLayout の定義を削除しました。
// TagSelectionView.swift 内の定義が自動的に使われます。
