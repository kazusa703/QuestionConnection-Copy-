import SwiftUI

// MARK: - QuizItemFormView (変更なし)
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

                ForEach($quizItem.choices) { $choice in
                    HStack {
                        TextField("選択肢", text: $choice.text)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            quizItem.correctAnswerId = choice.id
                        } label: {
                            Image(systemName: choice.id == quizItem.correctAnswerId ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(choice.id == quizItem.correctAnswerId ? .green : .secondary)
                        }
                    }
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
    @State private var purpose = "" // 目的を保持する状態変数
    @State private var tags = ""
    @State private var remarks = ""
    @State private var quizItems: [QuizItem] = [
        QuizItem(id: UUID().uuidString, questionText: "", choices: [
            Choice(id: UUID().uuidString, text: ""),
            Choice(id: UUID().uuidString, text: "")
        ], correctAnswerId: "")
    ]

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // 投稿ボタンを無効化するための計算プロパティ
    private var isPostButtonDisabled: Bool {
        return viewModel.isLoading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || purpose.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("質問の基本情報")) {
                    VStack(alignment: .leading) {
                        Text("題名")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("掲示板に表示されるタイトル", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("目的")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("目的を選択", selection: $purpose) {
                            Text("選択してください").tag("")
                            ForEach(viewModel.availablePurposes, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(.primary)
                    }

                    VStack(alignment: .leading) {
                        Text("タグ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("例: ご飯,パン,麺（カンマ区切り）", text: $tags)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading) {
                        Text("備考・説明")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $remarks)
                                .frame(height: 100)
                            if remarks.isEmpty {
                                Text("任意")
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

    private func postQuestion() {
         guard let authorId = authViewModel.userSub, let idToken = authViewModel.idToken else {
             alertMessage = "ユーザー情報が見つかりません。再ログインしてください。"
             showAlert = true
             return
         }
         
         if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              alertMessage = "題名を入力してください。"
              showAlert = true
              return
          }
          
         if purpose.isEmpty {
             alertMessage = "目的を選択してください。"
             showAlert = true
             return
         }
         
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

         let tagsArray = tags.split(separator: ",")
                           .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                           .filter { !$0.isEmpty }

         Task {
             let success = await viewModel.createQuestion(
                 title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                 tags: tagsArray,
                 remarks: remarks.trimmingCharacters(in: .whitespacesAndNewlines),
                 authorId: authorId,
                 quizItems: quizItems,
                 idToken: idToken,
                 purpose: purpose
             )

             if success {
                 alertMessage = "質問を投稿しました！"
                 // フォームをリセット
                 title = ""
                 purpose = ""
                 tags = ""
                 remarks = ""
                 quizItems = [QuizItem(id: UUID().uuidString, questionText: "", choices: [Choice(id: UUID().uuidString, text: ""), Choice(id: UUID().uuidString, text: "")], correctAnswerId: "")]
             } else {
                 alertMessage = "投稿に失敗しました。しばらくしてからもう一度お試しください。"
             }
             showAlert = true
         }
    }
}


