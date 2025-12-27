import SwiftUI

struct TagSelectionView: View {
    @Binding var selectedTags: [String]
    var maxTags: Int = 5
    
    @StateObject private var viewModel = TagViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // ★★★ 1. 入力欄 ★★★
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("タグを検索・追加", text: $inputText)
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
            
            // ★★★ 2. 検索結果（候補） ★★★
            if !inputText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // 検索結果がある場合
                    if !viewModel.searchResults.isEmpty {
                        Text("📊 候補")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.searchResults) { tag in
                            suggestionRow(tag: tag)
                        }
                    }
                    
                    // 新規タグ追加ボタン
                    newTagButton
                }
            }
            
            // ★★★ 3. 人気タグ（検索中でない場合） ★★★
            if inputText.isEmpty && !viewModel.popularTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("人気のタグ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TagFlowLayout(spacing: 8) {
                        ForEach(viewModel.popularTags) { tag in
                            tagChip(tag: tag)
                        }
                    }
                }
            }
            
            // ★★★ 4. 最近使われたタグ（検索中でない場合） ★★★
            if inputText.isEmpty {
                let filteredRecentTags = viewModel.recentTags.filter { tag in
                    !viewModel.popularTags.contains { $0.tagName == tag.tagName }
                }
                
                if !filteredRecentTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("最近使われたタグ")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        TagFlowLayout(spacing: 8) {
                            ForEach(filteredRecentTags) { tag in
                                tagChip(tag: tag)
                            }
                        }
                    }
                }
            }
            
            // ★★★ 5. 選択中のタグ ★★★
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("選択中のタグ (\(selectedTags.count)/\(maxTags))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TagFlowLayout(spacing: 8) {
                        ForEach(selectedTags, id: \.self) { tag in
                            selectedTagChip(tag: tag)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.fetchPopularTags()
            await viewModel.fetchRecentTags()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func tagChip(tag: TagSuggestion) -> some View {
        let isSelected = isTagSelected(tag.displayName)
        
        Button {
            toggleTag(tag.displayName)
        } label: {
            HStack(spacing: 4) {
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
        
        Button {
            toggleTag(tag.displayName)
            inputText = ""
            viewModel.searchResults = []
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text("#\(tag.displayName)")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(tag.usageCount)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var newTagButton: some View {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let existsInResults = viewModel.searchResults.contains { $0.displayName.lowercased() == trimmed.lowercased() }
        let alreadySelected = selectedTags.contains { $0.lowercased() == trimmed.lowercased() }
        
        if !trimmed.isEmpty && !existsInResults && !alreadySelected && selectedTags.count < maxTags {
            Button {
                addCustomTag()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("「\(trimmed)」を新しいタグとして追加")
                        .font(.subheadline)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 8)
            }
        }
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
        print("✅ タグ追加: \(tagName), 現在の選択: \(selectedTags)")
    }
    
    private func removeTag(_ tagName: String) {
        selectedTags.removeAll { $0.lowercased() == tagName.lowercased() }
        print("❌ タグ削除: \(tagName), 現在の選択: \(selectedTags)")
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
        print("✅ 新規タグ追加: \(trimmed), 現在の選択: \(selectedTags)")
        inputText = ""
        viewModel.searchResults = []
    }
}

// MARK: - TagFlowLayout

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                let position = result.positions[index]
                subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
            }
        }
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
