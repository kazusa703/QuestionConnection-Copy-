import SwiftUI

// MARK: - QuizItemFormView
struct QuizItemFormView: View {
    @Binding var quizItem: QuizItem
    var itemIndex: Int
    var deleteAction: () -> Void
    var canBeDeleted: Bool

    var body: some View {
        Section {
            HStack {
                Text("問題 \(itemIndex + 1)")
                Spacer()
                if canBeDeleted {
                    Button(role: .destructive) {
                        deleteAction()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }

            VStack(alignment: .leading) {
                Text("問題文")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $quizItem.questionText)
                        .frame(height: 100)
                    if quizItem.questionText.isEmpty {
                        Text("クイズの問題文を入力してください")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.top, 8).padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(UIColor.systemGray4), lineWidth: 1))
            }

            VStack(alignment: .leading) {
                Text("選択肢（正解の選択肢の○をタップ）")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 丸ボタンを左にしてヒット領域を拡大
                ForEach($quizItem.choices) { $choice in
                    HStack(spacing: 8) {
                        Button {
                            quizItem.correctAnswerId = choice.id
                        } label: {
                            Image(systemName: choice.id == quizItem.correctAnswerId ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(choice.id == quizItem.correctAnswerId ? .green : .secondary)
                                .frame(width: 32, height: 32, alignment: .center)
                                .contentShape(Rectangle())
                                .accessibilityLabel("この選択肢を正解にする")
                        }
                        .buttonStyle(.plain)

                        TextField("選択肢", text: $choice.text)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack {
                if quizItem.choices.count < 4 {
                    Button("選択肢を追加") {
                        quizItem.choices.append(Choice(id: UUID().uuidString, text: ""))
                    }
                    .buttonStyle(.borderless)
                }
                Spacer()
                if quizItem.choices.count > 2 {
                    Button("選択肢を削除", role: .destructive) {
                        if quizItem.correctAnswerId == quizItem.choices.last?.id {
                            quizItem.correctAnswerId = ""
                        }
                        quizItem.choices.removeLast()
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

// MARK: - CreateQuestionView
struct CreateQuestionView: View {
    @StateObject private var viewModel = QuestionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet
    
    @State private var title = ""
    @State private var purpose = "" // 目的
    
    // --- ★ 1. タグの @State を置き換え ---
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    // --- ★ 修正完了 (1) ---
    
    @State private var remarks = ""
    @State private var dmInviteMessage = "" // 全問正解者向けメッセージ（任意）
    @State private var quizItems: [QuizItem] = [
        QuizItem(id: UUID().uuidString, questionText: "", choices: [
            Choice(id: UUID().uuidString, text: ""),
            Choice(id: UUID().uuidString, text: "")
        ], correctAnswerId: "")
    ]
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // (isPostButtonDisabled は変更なし)
    private var isPostButtonDisabled: Bool {
        return viewModel.isLoading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("質問の基本情報")) {
                    VStack(alignment: .leading) {
                        Text("題名").font(.caption).foregroundColor(.secondary)
                        TextField("掲示板に表示されるタイトル", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("目的").font(.caption).foregroundColor(.secondary)
                        Picker("目的を選択", selection: $purpose) {
                            Text("選択なし").tag("")
                            ForEach(viewModel.availablePurposes, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(.primary)
                    }
                    
                    // --- ★ 2. タグ入力UIの変更 ---
                    VStack(alignment: .leading) {
                        Text("タグ（5個まで）").font(.caption).foregroundColor(.secondary)
                        HStack {
                            TextField("タグを入力して「追加」", text: $tagInput)
                                .textFieldStyle(.roundedBorder)
                            Button("追加") {
                                addTag()
                            }
                            .buttonStyle(.bordered)
                            .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tags.count >= 5)
                        }
                        
                        // 追加されたタグを表示するScrollView
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                        Button {
                                            removeTag(tag)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain) // ボタンのスタイルをリセット
                                }
                            }
                            .padding(.top, 5) // タグ入力欄との間に少し余白
                        }
                        .frame(minHeight: (tags.isEmpty ? 0 : 35)) // タグがない場合は高さを0に
                    }
                    // --- ★ 修正完了 (2) ---
                    
                    VStack(alignment: .leading) {
                        Text("備考・説明").font(.caption).foregroundColor(.secondary)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $remarks).frame(height: 100)
                            if remarks.isEmpty {
                                Text("任意").foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.top, 8).padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(UIColor.systemGray4), lineWidth: 1))
                    }
                    
                    // ここが追加の入力欄
                    VStack(alignment: .leading) {
                        Text("全問正解者へのメッセージ（任意）").font(.caption).foregroundColor(.secondary)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $dmInviteMessage).frame(height: 80)
                            if dmInviteMessage.isEmpty {
                                Text("例: 全問正解おめでとう！DMください")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.top, 8).padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(UIColor.systemGray4), lineWidth: 1))
                    }
                }
                
                ForEach($quizItems.indices, id: \.self) { index in
                    QuizItemFormView(
                        quizItem: $quizItems[index],
                        itemIndex: index,
                        deleteAction: { deleteQuizItem(at: index) },
                        canBeDeleted: quizItems.count > 1
                    )
                }
                
                HStack {
                    if quizItems.count < 5 {
                        Button("問題を追加") { addQuizItem() }
                            .buttonStyle(.borderless)
                    }
                    Spacer()
                }
                
                Section {
                    Button {
                        if authViewModel.isSignedIn {
                            postQuestion()
                        } else {
                            showAuthenticationSheet.wrappedValue = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text(authViewModel.isSignedIn ? "投稿する" : "ログインして投稿")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isPostButtonDisabled)
                }
            }
            .navigationTitle("新しい質問を作成")
            .alert("QuestionConnection", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task {
                viewModel.setAuthViewModel(authViewModel)
            }
        }
    }
    
    private func addQuizItem() {
        quizItems.append(QuizItem(id: UUID().uuidString, questionText: "", choices: [
            Choice(id: UUID().uuidString, text: ""),
            Choice(id: UUID().uuidString, text: "")
        ], correctAnswerId: ""))
    }
    
    private func deleteQuizItem(at index: Int) {
        guard quizItems.count > 1 else { return }
        guard index < quizItems.count else { return }
        quizItems.remove(at: index)
    }
    
    // --- ★ 3. 提案されたヘルパー関数を追加 ---
    // タグ追加処理
    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        // タグの上限（5個まで）
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag), tags.count < 5 else {
            tagInput = "" // 上限の場合も入力欄はクリア
            return
        }
        tags.append(trimmedTag)
        tagInput = ""
    }
    
    // タグ削除処理
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    // --- ★ 修正完了 (3) ---
    
    private func postQuestion() {
        guard let authorId = authViewModel.userSub else {
            alertMessage = "ユーザー情報が見つかりません。再ログインしてください。"
            showAlert = true
            return
        }
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "題名を入力してください。"
            showAlert = true
            return
        }
        
        // (目的のバリデーション削除は反映済み)
        
        for (index, item) in quizItems.enumerated() {
            if item.questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "問題 \(index + 1) の問題文が空です。"
                showAlert = true
                return
            }
            if item.choices.count < 2 {
                alertMessage = "問題 \(index + 1) の選択肢は2つ以上必要です。"
                showAlert = true
                return
            }
            if item.correctAnswerId.isEmpty || !item.choices.contains(where: { $0.id == item.correctAnswerId }) {
                alertMessage = "問題 \(index + 1) の正解が選択されていません。"
                showAlert = true
                return
            }
            for (choiceIndex, choice) in item.choices.enumerated() {
                if choice.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    alertMessage = "問題 \(index + 1) の選択肢 \(choiceIndex + 1) が空です。"
                    showAlert = true
                    return
                }
            }
        }
        
        // --- ★ 4. tagsArray の作成ロジックを削除 (変更済み) ---
        
        Task {
            let success = await viewModel.createQuestion(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                // ★ 5. @State の `tags` をそのまま渡す ★
                tags: tags,
                remarks: remarks.trimmingCharacters(in: .whitespacesAndNewlines),
                authorId: authorId,
                quizItems: quizItems,
                purpose: purpose, // そのまま渡す (空文字列 or 値)
                dmInviteMessage: dmInviteMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : dmInviteMessage
            )
            
            // --- ★★★ ここから修正 ★★★ ---
            // UIの更新を MainActor (メインスレッド) で実行する
            await MainActor.run {
                if success {
                    alertMessage = "質問を投稿しました！"
                    // フォームをリセット
                    title = ""
                    purpose = ""
                    tags = []
                    tagInput = ""
                    remarks = ""
                    dmInviteMessage = ""
                    quizItems = [QuizItem(
                        id: UUID().uuidString,
                        questionText: "",
                        choices: [Choice(id: UUID().uuidString, text: ""), Choice(id: UUID().uuidString, text: "")],
                        correctAnswerId: ""
                    )]
                } else {
                    alertMessage = "投稿に失敗しました。しばらくしてからもう一度お試しください。"
                }
                showAlert = true
            }
            // --- ★★★ 修正ここまで ★★★ ---
        }
    }
}
