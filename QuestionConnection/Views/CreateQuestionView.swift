import SwiftUI

// MARK: - CreateQuestionView
struct CreateQuestionView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    private let adManager = InterstitialAdManager()
    
    @State private var title = ""
    @State private var purpose = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var remarks = ""
    @State private var dmInviteMessage = ""
    
    @State private var quizItems: [QuizItem] = [
        QuizItem(id: UUID().uuidString, type: .choice, questionText: "", choices: [
            Choice(id: UUID().uuidString, text: ""),
            Choice(id: UUID().uuidString, text: "")
        ], correctAnswerId: "")
    ]
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isAdLoading = false
    @State private var showConfirmation = false
    @State private var showTagSheet = false
    
    // ガイド表示用
    @State private var showGuide = false
    
    var shouldShowBanner: Bool {
        !subscriptionManager.isPremium
    }

    var body: some View {
        VStack(spacing: 0) {
            if shouldShowBanner {
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
            }
            
            Form {
                basicInfoSection
                quizItemsSection
                submitButtonSection
            }
        }
        .navigationTitle("作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("作成")
                        .font(.headline)
                    Button(action: { showGuide = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("通知", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showConfirmation) {
            QuestionConfirmationView(
                title: title,
                purpose: purpose,
                tags: tags,
                remarks: remarks,
                dmInviteMessage: dmInviteMessage,
                quizItems: renumberHolesInQuizItems(quizItems),
                subscriptionManager: subscriptionManager,
                isLoading: viewModel.isLoading || isAdLoading,
                onPost: executeFinalPost
            )
        }
        .sheet(isPresented: $showTagSheet) {
            TagSelectionSheet(selectedTags: $tags)
        }
        .sheet(isPresented: $showGuide) {
            QuestionCreationGuideView()
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            adManager.loadAd()
        }
    }
    
    // --- 1. 基本情報セクション ---
    private var basicInfoSection: some View {
        Group {
            Section(header: Text("質問の基本情報")) {
                TextField("題名", text: $title)
                Picker("目的", selection: $purpose) {
                    Text("選択なし").tag("")
                    ForEach(viewModel.availablePurposes, id: \.self) { p in
                        Text(p).tag(p)
                    }
                }
                TextField("備考・説明", text: $remarks)
                TextField("全問正解者へのメッセージ", text: $dmInviteMessage)
            }
            
            Section(header: Text("タグ (任意・最大5個)")) {
                Button {
                    showTagSheet = true
                } label: {
                    HStack {
                        Image(systemName: "tag.fill").foregroundColor(.blue)
                        Text("タグを追加・編集").foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
                    }
                }
                if !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("選択中のタグ").font(.caption).foregroundColor(.secondary)
                        FlowLayoutView(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)").font(.subheadline)
                                    Button { tags.removeAll { $0 == tag } } label: {
                                        Image(systemName: "xmark.circle.fill").font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // --- 2. 問題作成セクション ---
    private var quizItemsSection: some View {
        ForEach(quizItems.indices, id: \.self) { index in
            Section(header: Text("問題 \(index + 1)")) {
                Picker("形式", selection: Binding(
                    get: { quizItems[index].type },
                    set: { quizItems[index].type = $0 }
                )) {
                    Text("選択式").tag(QuizType.choice)
                    Text("穴埋め").tag(QuizType.fillIn)
                    if subscriptionManager.isPremium {
                        Text("記述式").tag(QuizType.essay)
                    } else {
                        Text("記述式 (👑)").tag(QuizType.essay)
                    }
                }
                .pickerStyle(.segmented)
                
                switch quizItems[index].type {
                case .choice:
                    ChoiceQuestionEditor(item: $quizItems[index])
                case .fillIn:
                    FillInQuestionEditor(item: $quizItems[index])
                case .essay:
                    EssayQuestionEditor(item: $quizItems[index])
                }
                
                if quizItems.count > 1 {
                    Button("この問題を削除", role: .destructive) {
                        withAnimation { _ = quizItems.remove(at: index) }
                    }
                }
            }
        }
    }
    
    // --- 3. 投稿ボタンセクション ---
    private var submitButtonSection: some View {
        Group {
            Button("問題を追加") {
                quizItems.append(QuizItem(id: UUID().uuidString, type: .choice, questionText: ""))
            }
            Section {
                Button {
                    if authViewModel.isSignedIn {
                        if validateInputs() {
                            showConfirmation = true
                        }
                    } else {
                        showAuthenticationSheet.wrappedValue = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading || isAdLoading {
                            ProgressView()
                        } else {
                            Text(authViewModel.isSignedIn ? "投稿へ" : "ログインして投稿")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading || isAdLoading)
            }
        }
    }
    
    // MARK: - ロジック (バリデーション等)
    private func validateInputs() -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "題名が空白です。"
            showAlert = true
            return false
        }
        for (index, item) in quizItems.enumerated() {
            let qNum = index + 1
            if item.questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "問題 \(qNum) の文章が空白です。"
                showAlert = true
                return false
            }
            switch item.type {
            case .choice:
                for choice in item.choices {
                    if choice.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        alertMessage = "問題 \(qNum) の選択肢が空白です。"
                        showAlert = true
                        return false
                    }
                }
                if item.correctAnswerId.isEmpty {
                    alertMessage = "問題 \(qNum) の正解（◯）が選択されていません。"
                    showAlert = true
                    return false
                }
            case .fillIn:
                if item.fillInAnswers.isEmpty {
                    alertMessage = "問題 \(qNum) に穴埋め箇所がありません。"
                    showAlert = true
                    return false
                }
                for (key, val) in item.fillInAnswers {
                    if val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let num = extractNumber(from: key)
                        alertMessage = "問題 \(qNum) の (\(num)) の正解が空白です。"
                        showAlert = true
                        return false
                    }
                }
            case .essay: break
            }
        }
        
        let hasEssayQuestion = quizItems.contains { $0.type == .essay }
        if hasEssayQuestion && !subscriptionManager.isPremium {
            alertMessage = "記述式問題の投稿はプレミアムプラン限定です。"
            showAlert = true
            return false
        }
        
        // NGワードチェック
        let textToCheck = [title, remarks, dmInviteMessage]
        if case .blocked(let reason) = NGWordFilter.shared.checkMultiple(textToCheck) {
            alertMessage = "入力内容に不適切な表現が含まれています。\n理由: \(reason)"
            showAlert = true
            return false
        }
        // 他のNGワードチェック省略（既存同様）
        return true
    }
    
    private func executeFinalPost() {
        if subscriptionManager.isPremium {
            executePostAPI()
        } else {
            let currentCount = UserDefaults.standard.integer(forKey: "postCount") + 1
            UserDefaults.standard.set(currentCount, forKey: "postCount")
            if currentCount % 3 == 0 {
                isAdLoading = true
                adManager.showAd {
                    isAdLoading = false
                    executePostAPI()
                }
            } else {
                executePostAPI()
            }
        }
    }
    
    private func executePostAPI() {
        let renumberedItems = renumberHolesInQuizItems(quizItems)
        Task {
            guard let uid = authViewModel.userSub else { return }
            let success = await viewModel.createQuestion(
                title: title, tags: tags, remarks: remarks, authorId: uid,
                quizItems: renumberedItems, purpose: purpose, dmInviteMessage: dmInviteMessage
            )
            await MainActor.run {
                if success {
                    showConfirmation = false
                    alertMessage = "投稿しました！"
                    title = ""; tags = []
                    quizItems = [QuizItem(id: UUID().uuidString, type: .choice, questionText: "")]
                    showAlert = true
                } else {
                    alertMessage = "投稿に失敗しました。"
                    showAlert = true
                }
            }
        }
    }
    
    private func renumberHolesInQuizItems(_ items: [QuizItem]) -> [QuizItem] {
        return items.map { item in
            if item.type == .fillIn { return renumberHoles(in: item) }
            return item
        }
    }
    
    private func renumberHoles(in item: QuizItem) -> QuizItem {
        var newItem = item
        let pattern = "\\[穴(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return item }
        let text = item.questionText
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var oldNumbers: [Int] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: text), let num = Int(text[range]) {
                if !oldNumbers.contains(num) { oldNumbers.append(num) }
            }
        }
        var numberMapping: [Int: Int] = [:]
        for (index, oldNum) in oldNumbers.enumerated() { numberMapping[oldNum] = index + 1 }
        var newText = text
        for oldNum in oldNumbers.sorted().reversed() {
            if let newNum = numberMapping[oldNum] {
                newText = newText.replacingOccurrences(of: "[穴\(oldNum)]", with: "[@@\(newNum)@@]")
            }
        }
        newText = newText.replacingOccurrences(of: "[@@", with: "[穴")
        newText = newText.replacingOccurrences(of: "@@]", with: "]")
        newItem.questionText = newText
        var newFillInAnswers: [String: String] = [:]
        for (key, value) in item.fillInAnswers {
            let oldNum = extractNumber(from: key)
            if let newNum = numberMapping[oldNum] {
                newFillInAnswers["穴\(newNum)"] = value
            }
        }
        newItem.fillInAnswers = newFillInAnswers
        return newItem
    }
    
    private func extractNumber(from key: String) -> Int {
        return Int(key.replacingOccurrences(of: "穴", with: "")) ?? (Int(key) ?? 0)
    }
}

// MARK: - CreateQuestionView内で使用するエディタ部品

struct ChoiceQuestionEditor: View {
    @Binding var item: QuizItem
    var body: some View {
        TextField("問題文", text: $item.questionText)
        ForEach($item.choices.indices, id: \.self) { index in
            HStack {
                Button { item.correctAnswerId = item.choices[index].id } label: {
                    Image(systemName: item.correctAnswerId == item.choices[index].id ? "checkmark.circle.fill" : "circle")
                }
                TextField("選択肢", text: $item.choices[index].text)
                if item.choices.count > 2 {
                    Button(role: .destructive) { deleteChoice(at: index) } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }
            }
        }
        Button("選択肢を追加") {
            item.choices.append(Choice(id: UUID().uuidString, text: ""))
        }
    }
    private func deleteChoice(at index: Int) {
        let deletedId = item.choices[index].id
        item.choices.remove(at: index)
        if item.correctAnswerId == deletedId { item.correctAnswerId = "" }
    }
}

struct FillInQuestionEditor: View {
    @Binding var item: QuizItem
    @State private var tempText: String = ""
    @State private var showDeleteAlert = false
    @State private var holeToDelete: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("プレビュー").font(.caption).foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 4) {
                    Text("Q1.").font(.headline).fontWeight(.bold)
                    // ★ プレビュー表示: FillInQuestionTextOutlined (枠線付き) を使用
                    FillInQuestionTextOutlined(text: tempText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("穴ボタンを押すと穴埋め箇所を追加できます").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    // 入力欄はテキストのまま [穴1]
                    TextField("文章を入力...", text: $tempText)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 44)
                    Button(action: insertHole) {
                        Text("穴")
                            .font(.headline).fontWeight(.bold).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Divider()
            if !item.fillInAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("正解を入力してください").font(.subheadline).fontWeight(.medium)
                    ForEach(Array(item.fillInAnswers.keys.sorted { sortKeys($0, $1) }), id: \.self) { key in
                        HStack(spacing: 12) {
                            // ★ 変更点: 青四角(FillInBoxSmall)を枠線付き(FillInNumberBox)に変更
                            FillInNumberBox(number: extractNumber(from: key))
                            
                            TextField("正解", text: Binding(
                                get: { item.fillInAnswers[key] ?? "" },
                                set: { item.fillInAnswers[key] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            Button(role: .destructive) {
                                holeToDelete = extractNumber(from: key)
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            tempText = convertOldHoleFormat(item.questionText)
            convertOldFillInAnswers()
        }
        .onChange(of: tempText) { _, newValue in
            item.questionText = newValue
            syncAnswers()
        }
        .alert("削除の確認", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) { holeToDelete = nil }
            Button("削除", role: .destructive) {
                if let number = holeToDelete { deleteHole(number: number) }
                holeToDelete = nil
            }
        } message: {
            if let number = holeToDelete { Text("(\(number)) を削除しますか？") }
        }
    }
    
    // ロジック系 (省略なし)
    func convertOldHoleFormat(_ text: String) -> String {
        return text.replacingOccurrences(of: "\\[([0-9]+)\\]", with: "[穴$1]", options: .regularExpression)
    }
    func convertOldFillInAnswers() {
        var newAnswers: [String: String] = [:]
        for (key, value) in item.fillInAnswers {
            if !key.contains("穴") {
                newAnswers["穴\(key)"] = value
            } else {
                newAnswers[key] = value
            }
        }
        if newAnswers != item.fillInAnswers { item.fillInAnswers = newAnswers }
    }
    func insertHole() {
        let nextNumber = findNextHoleNumber()
        tempText += "[穴\(nextNumber)]"
    }
    func findNextHoleNumber() -> Int {
        let pattern = "\\[穴(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 1 }
        let matches = regex.matches(in: tempText, range: NSRange(tempText.startIndex..., in: tempText))
        var existingNumbers: Set<Int> = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: tempText), let num = Int(tempText[range]) {
                existingNumbers.insert(num)
            }
        }
        var next = 1
        while existingNumbers.contains(next) { next += 1 }
        return next
    }
    func deleteHole(number: Int) {
        tempText = tempText.replacingOccurrences(of: "[穴\(number)]", with: "")
        item.fillInAnswers.removeValue(forKey: "穴\(number)")
    }
    func syncAnswers() {
        let pattern = "\\[穴(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: tempText, range: NSRange(tempText.startIndex..., in: tempText))
        var foundKeys = Set<String>()
        for match in matches {
            if let range = Range(match.range(at: 1), in: tempText) {
                foundKeys.insert("穴" + String(tempText[range]))
            }
        }
        // 不足しているキーを追加
        for key in foundKeys {
            if item.fillInAnswers[key] == nil { item.fillInAnswers[key] = "" }
        }
        // 不要なキーを削除
        item.fillInAnswers = item.fillInAnswers.filter { foundKeys.contains($0.key) }
    }
    private func sortKeys(_ key1: String, _ key2: String) -> Bool {
        return extractNumber(from: key1) < extractNumber(from: key2)
    }
    private func extractNumber(from key: String) -> Int {
        return Int(key.replacingOccurrences(of: "穴", with: "")) ?? 0
    }
}

struct EssayQuestionEditor: View {
    @Binding var item: QuizItem
    var body: some View {
        VStack(alignment: .leading) {
            Text("問題文")
            TextEditor(text: $item.questionText)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5)))
            Text("模範解答（採点の参考に表示されます）")
            TextEditor(text: Binding(
                get: { item.modelAnswer ?? "" },
                set: { item.modelAnswer = $0 }
            ))
            .frame(height: 100)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5)))
        }
    }
}

// 簡易FlowLayout
struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    var body: some View {
        // TagFlowLayoutがなければHStack等で代用。ここではエラー回避のためLazyVGrid等を想定するか、外部定義を利用
        // コンパイルを通すため仮実装
        HStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - 確認画面ビュー
struct QuestionConfirmationView: View {
    let title: String
    let purpose: String
    let tags: [String]
    let remarks: String
    let dmInviteMessage: String
    let quizItems: [QuizItem]
    
    @ObservedObject var subscriptionManager: SubscriptionManager
    let isLoading: Bool
    let onPost: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                if !purpose.isEmpty {
                                    Text(purpose)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(8)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        if !remarks.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("備考・説明").font(.headline)
                                Text(remarks).foregroundColor(.primary)
                            }
                        } else {
                            Text("（備考はありません）")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Text("問題一覧").font(.headline)
                        
                        ForEach(quizItems.indices, id: \.self) { index in
                            let item = quizItems[index]
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("問題 \(index + 1)")
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Text(itemTypeString(item.type))
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                if item.type == .fillIn {
                                    FillInQuestionTextOutlined(text: item.questionText, font: .body.bold())
                                } else {
                                    Text(item.questionText)
                                        .font(.body)
                                        .bold()
                                }
                                
                                Group {
                                    if item.type == .choice {
                                        ForEach(item.choices) { choice in
                                            HStack {
                                                Image(systemName: choice.id == item.correctAnswerId ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(choice.id == item.correctAnswerId ? .green : .gray)
                                                Text(choice.text)
                                            }
                                        }
                                    } else if item.type == .fillIn {
                                        VStack(alignment: .leading, spacing: 4) {
                                            // ★★★ 修正: ソートと表示のロジックを変更 ★★★
                                            // キーから「穴」を取り除いて数値としてソート
                                            ForEach(Array(item.fillInAnswers.keys.sorted { extractNumber(from: $0) < extractNumber(from: $1) }), id: \.self) { key in
                                                HStack(spacing: 8) {
                                                    // ★★★ 修正: 正しく数値を抽出して表示 ★★★
                                                    FillInNumberBox(number: extractNumber(from: key))
                                                    Text("= \(item.fillInAnswers[key] ?? "")")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    } else if item.type == .essay {
                                        if let model = item.modelAnswer, !model.isEmpty {
                                            Text("模範解答: \(model)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.leading, 10)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }
                        
                        if !dmInviteMessage.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("全問正解者へのメッセージ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(dmInviteMessage)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                
                VStack {
                    if !subscriptionManager.isPremium {
                        Text("※ 投稿時に広告が表示される場合があります")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    Button(action: onPost) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("この内容で投稿する")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(radius: 2, y: -2)
            }
            .navigationTitle("投稿の確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("修正") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func itemTypeString(_ type: QuizType) -> String {
        switch type {
        case .choice: return "選択式"
        case .fillIn: return "穴埋め"
        case .essay: return "記述式"
        }
    }
    
    // ★★★ 追加: キーから数値を抽出するヘルパー関数 ★★★
    private func extractNumber(from key: String) -> Int {
        // "穴1" -> 1 に変換。失敗したら0
        return Int(key.replacingOccurrences(of: "穴", with: "")) ?? 0
    }
}
