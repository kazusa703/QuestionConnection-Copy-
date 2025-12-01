import SwiftUI

// MARK: - CreateQuestionView
struct CreateQuestionView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // ★ SubscriptionManager に修正
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
    
    // バナー広告の表示制御
    var shouldShowBanner: Bool {
        !subscriptionManager.isPremium
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // バナー広告
                if shouldShowBanner {
                    AdBannerView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                }
                
                Form {
                    // ★ 部品に分けました（コンパイルエラー対策）
                    basicInfoSection
                    quizItemsSection
                    submitButtonSection
                }
            }
            .navigationTitle("作成")
            .navigationBarTitleDisplayMode(.inline)
            .alert("通知", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .task {
                viewModel.setAuthViewModel(authViewModel)
                adManager.loadAd()
            }
        }
    }
    
    // --- 1. 基本情報セクション ---
    private var basicInfoSection: some View {
        Section(header: Text("質問の基本情報")) {
            TextField("題名", text: $title)
            
            Picker("目的", selection: $purpose) {
                Text("選択なし").tag("")
                ForEach(viewModel.availablePurposes, id: \.self) { p in
                    Text(p).tag(p)
                }
            }
            
            HStack {
                TextField("タグ (追加)", text: $tagInput)
                Button("追加") {
                    if !tagInput.isEmpty && tags.count < 5 {
                        tags.append(tagInput)
                        tagInput = ""
                    }
                }
            }
            if !tags.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag).padding(5).background(Color.blue.opacity(0.1)).cornerRadius(5)
                        }
                    }
                }
            }
            
            TextField("備考・説明", text: $remarks)
            TextField("全問正解者へのメッセージ", text: $dmInviteMessage)
        }
    }
    
    // --- 2. 問題作成セクション ---
    private var quizItemsSection: some View {
        ForEach($quizItems.indices, id: \.self) { index in
            Section(header: Text("問題 \(index + 1)")) {
                Picker("形式", selection: $quizItems[index].type) {
                    Text("選択式").tag(QuizType.choice)
                    Text("穴埋め").tag(QuizType.fillIn)
                    Text("記述式").tag(QuizType.essay)
                }
                .pickerStyle(.segmented)
                
                // タイプごとのエディタ呼び出し
                if quizItems[index].type == .choice {
                    ChoiceQuestionEditor(item: $quizItems[index])
                } else if quizItems[index].type == .fillIn {
                    FillInQuestionEditor(item: $quizItems[index])
                } else {
                    EssayQuestionEditor(item: $quizItems[index])
                }
                
                if quizItems.count > 1 {
                    Button("この問題を削除", role: .destructive) {
                        quizItems.remove(at: index)
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
                        handlePostButtonTap()
                    } else {
                        showAuthenticationSheet.wrappedValue = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading || isAdLoading {
                            ProgressView()
                        } else {
                            Text(authViewModel.isSignedIn ? "投稿する" : "ログインして投稿")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(title.isEmpty || viewModel.isLoading || isAdLoading)
            }
        }
    }
    
    private func handlePostButtonTap() {
        if title.isEmpty { return }
        
        if subscriptionManager.isPremium {
            executePost()
        } else {
            isAdLoading = true
            adManager.showAd {
                isAdLoading = false
                executePost()
            }
        }
    }
    
    private func executePost() {
        Task {
            guard let uid = authViewModel.userSub else { return }
            let success = await viewModel.createQuestion(
                title: title,
                tags: tags,
                remarks: remarks,
                authorId: uid,
                quizItems: quizItems,
                purpose: purpose,
                dmInviteMessage: dmInviteMessage
            )
            
            await MainActor.run {
                if success {
                    alertMessage = "投稿しました！"
                    title = ""; tags = []; quizItems = [QuizItem(id: UUID().uuidString, type: .choice, questionText: "")]
                } else {
                    alertMessage = "投稿に失敗しました。"
                }
                showAlert = true
            }
        }
    }
}

// MARK: - 各問題タイプのエディタ部品
// ★ ここから下が「Cannot find...」の原因だった部分です。必ず含めてください。

// 1. 選択式エディタ
struct ChoiceQuestionEditor: View {
    @Binding var item: QuizItem
    
    var body: some View {
        TextField("問題文", text: $item.questionText)
        
        ForEach($item.choices) { $choice in
            HStack {
                Button {
                    item.correctAnswerId = choice.id
                } label: {
                    Image(systemName: item.correctAnswerId == choice.id ? "checkmark.circle.fill" : "circle")
                }
                TextField("選択肢", text: $choice.text)
            }
        }
        
        Button("選択肢を追加") {
            item.choices.append(Choice(id: UUID().uuidString, text: ""))
        }
    }
}

// 2. 穴埋めエディタ
struct FillInQuestionEditor: View {
    @Binding var item: QuizItem
    @State private var tempText: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("文章を作成し、[穴]ボタンでカーソル位置に穴を挿入します。")
                .font(.caption).foregroundColor(.secondary)
            
            HStack {
                TextField("文章を入力...", text: $tempText)
                    .textFieldStyle(.roundedBorder)
                
                Button("穴") {
                    insertHole()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("プレビュー: " + tempText)
                .font(.body)
                .padding(.vertical, 4)
            
            Divider()
            
            Text("正解を入力してください").font(.caption)
            ForEach(Array(item.fillInAnswers.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                    TextField("正解", text: Binding(
                        get: { item.fillInAnswers[key] ?? "" },
                        set: { item.fillInAnswers[key] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
        .onAppear {
            tempText = item.questionText
        }
        .onChange(of: tempText) { _, newValue in
            item.questionText = newValue
            syncAnswers()
        }
    }
    
    func insertHole() {
        let holeCount = item.fillInAnswers.count + 1
        let holeTag = "[穴\(holeCount)]"
        tempText += holeTag
    }
    
    func syncAnswers() {
        let pattern = "\\[(穴\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: tempText, range: NSRange(tempText.startIndex..., in: tempText))
        
        var foundKeys = Set<String>()
        for match in matches {
            if let range = Range(match.range(at: 1), in: tempText) {
                let key = String(tempText[range])
                foundKeys.insert(key)
                if item.fillInAnswers[key] == nil {
                    item.fillInAnswers[key] = ""
                }
            }
        }
        item.fillInAnswers = item.fillInAnswers.filter { foundKeys.contains($0.key) }
    }
}

// 3. 記述式エディタ
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
