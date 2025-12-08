import SwiftUI

// MARK: - CreateQuestionView
struct CreateQuestionView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // 課金管理
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
        VStack(spacing: 0) {
            // バナー広告
            if shouldShowBanner {
                AdBannerView()
                    . frame(height: 50)
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
                ScrollView(. horizontal) {
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
                
                // タイプごとのエディタ呼び出し
                switch quizItems[index].type {
                case .choice:
                    ChoiceQuestionEditor(item: Binding(
                        get: { quizItems[index] },
                        set: { quizItems[index] = $0 }
                    ))
                case .fillIn:
                    FillInQuestionEditor(item: Binding(
                        get: { quizItems[index] },
                        set: { quizItems[index] = $0 }
                    ))
                case .essay:
                    EssayQuestionEditor(item: Binding(
                        get: { quizItems[index] },
                        set: { quizItems[index] = $0 }
                    ))
                }
                
                if quizItems.count > 1 {
                    Button("この問題を削除", role: . destructive) {
                        withAnimation {
                            _ = quizItems.remove(at: index)
                        }
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
                // ★ 修正: ローディング中だけ押せないようにする
                . disabled(viewModel.isLoading || isAdLoading)
            }
        }
    }
    
    // ★★★ 修正: 入力バリデーションを追加 ★★★
    // MARK: - 投稿ボタン処理 (バリデーション付き)
        
        private func handlePostButtonTap() {
            // --- 0. 入力バリデーション ---
            
            // 1. 題名チェック
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "題名が空白です。"
                showAlert = true
                return
            }
            
            // 2. 目的チェック
            if purpose.isEmpty {
                alertMessage = "目的が選択されていません。"
                showAlert = true
                return
            }
            
            // 3. 各問題のチェック
            for (index, item) in quizItems.enumerated() {
                let qNum = index + 1
                
                // 問題文チェック
                if item.questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    alertMessage = "問題 \(qNum) の文章が空白です。"
                    showAlert = true
                    return
                }
                
                // --- タイプ別の詳細チェック ---
                switch item.type {
                case .choice:
                    // 選択肢の空白チェック
                    for (cIndex, choice) in item.choices.enumerated() {
                        if choice.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            alertMessage = "問題 \(qNum) の選択肢 \(cIndex + 1) が空白です。"
                            showAlert = true
                            return
                        }
                    }
                    
                    // 正解選択チェック
                    if item.correctAnswerId.isEmpty {
                        alertMessage = "問題 \(qNum) の正解（◯）が選択されていません。"
                        showAlert = true
                        return
                    }
                    
                case .fillIn:
                    // 穴埋めの正解チェック
                    if item.fillInAnswers.isEmpty {
                        alertMessage = "問題 \(qNum) に穴埋め箇所がありません。「穴」ボタンで作成してください。"
                        showAlert = true
                        return
                    }
                    // 各穴の正解テキストチェック
                    for (key, val) in item.fillInAnswers {
                        if val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            alertMessage = "問題 \(qNum) の [\(key)] の正解が空白です。"
                            showAlert = true
                            return
                        }
                    }
                    
                case .essay:
                    // 記述式は問題文さえあればOK（模範解答は任意）
                    break
                }
            }
            // ----------------------------------------
            
            // --- 1. プレミアム機能のチェック ---
            let hasEssayQuestion = quizItems.contains { $0.type == .essay }
            
            if hasEssayQuestion && !subscriptionManager.isPremium {
                alertMessage = "記述式問題の投稿はプレミアムプラン限定の機能です。\n設定画面からアップグレードしてください。"
                showAlert = true
                return
            }
            
            // --- 2. 広告表示ロジック (3回に1回) ---
            if subscriptionManager.isPremium {
                // 有料会員なら即投稿
                executePost()
            } else {
                // 無料会員: カウンターを更新して判定
                let currentCount = UserDefaults.standard.integer(forKey: "postCount") + 1
                UserDefaults.standard.set(currentCount, forKey: "postCount")
                
                print("現在の投稿回数: \(currentCount)")
                
                // 3回に1回 (3で割り切れる時) だけ広告を表示
                if currentCount % 3 == 0 {
                    isAdLoading = true
                    adManager.showAd {
                        isAdLoading = false
                        executePost()
                    }
                } else {
                    // それ以外は広告なしで投稿
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
                    // リセット
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

// 1. 選択式エディタ
struct ChoiceQuestionEditor: View {
    @Binding var item: QuizItem
    
    var body: some View {
        TextField("問題文", text: $item.questionText)
        
        // --- 選択肢のリスト（削除ボタン付き） ---
        ForEach($item.choices.indices, id: \.self) { index in
            HStack {
                // 正解選択ボタン
                Button {
                    item.correctAnswerId = item.choices[index].id
                } label: {
                    Image(systemName: item.correctAnswerId == item.choices[index].id ? "checkmark.circle.fill" : "circle")
                }
                
                // 選択肢入力
                TextField("選択肢", text: $item.choices[index].text)
                
                // ★★★ 追加: 削除ボタン (選択肢が2つより多い場合のみ表示) ★★★
                if item.choices.count > 2 {
                    Button(role: .destructive) {
                        deleteChoice(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        
        Button("選択肢を追加") {
            item.choices.append(Choice(id: UUID().uuidString, text: ""))
        }
    }
    
    // 削除処理
    private func deleteChoice(at index: Int) {
        let deletedId = item.choices[index].id
        item.choices.remove(at: index)
        
        // もし正解として選ばれていた選択肢を消した場合は、正解設定をリセット
        if item.correctAnswerId == deletedId {
            item.correctAnswerId = ""
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
                TextField("文章を入力.. .", text: $tempText)
                    .textFieldStyle(. roundedBorder)
                
                Button("穴") {
                    insertHole()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("プレビュー: " + tempText)
                .font(.body)
                .padding(. vertical, 4)
            
            Divider()
            
            Text("正解を入力してください").font(.caption)
            ForEach(Array(item.fillInAnswers.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                    TextField("正解", text: Binding(
                        get: { item.fillInAnswers[key] ??  "" },
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
