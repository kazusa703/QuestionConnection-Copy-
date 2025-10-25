import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()

    // --- 絞り込み機能用の状態変数 ---
    @State private var showingFilterSheet = false
    @State private var selectedPurpose = "" // 「すべて」を空文字で表現

    @State private var searchText = ""

    // 検索バー用の絞り込みロジック (変更なし)
    private var filteredQuestions: [Question] {
        if searchText.isEmpty {
            return viewModel.questions
        } else {
            return viewModel.questions.filter { question in
                let titleMatch = question.title.localizedCaseInsensitiveContains(searchText)
                let tagMatch = question.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }
                return titleMatch || tagMatch
            }
        }
    }

    // --- 絞り込みが適用されているかどうかの判定 ---
    private var isFilterActive: Bool {
        return !selectedPurpose.isEmpty
    }

    // --- 適用中の絞り込み条件を説明するテキスト ---
    private var activeFilterDescription: String {
        var descriptions: [String] = []
        if !selectedPurpose.isEmpty {
            descriptions.append("目的: \(selectedPurpose)")
        }
        return descriptions.joined() // 区切り文字不要
    }

    var body: some View {
        NavigationStack {
            VStack {
                // --- 適用中のフィルタがあれば表示 ---
                if isFilterActive {
                    HStack {
                        Text(activeFilterDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            // リセット処理
                            selectedPurpose = ""
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
                    Text(isFilterActive ? "指定された条件の質問はありません。" : "まだ質問がありません。")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(filteredQuestions) { question in
                        // ★★★ QuestionDetailView があれば正しく動作 ★★★
                         NavigationLink(destination: QuestionDetailView(question: question)) {
                            VStack(alignment: .leading) {
                                Text(question.title)
                                    .font(.headline)
                                Text("タグ: \(question.tags.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        // ★★★ なければ一時的に Text で表示 ★★★
                        /*
                        VStack(alignment: .leading) {
                           Text(question.title)
                               .font(.headline)
                           Text("タグ: \(question.tags.joined(separator: ", "))")
                               .font(.caption)
                               .foregroundColor(.secondary)
                        }
                        */
                    }
                }
            }
            .navigationTitle("掲示板")
            .searchable(text: $searchText, prompt: "タイトルやタグで検索")
            // --- ツールバーに絞り込みボタンを追加 ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            // --- 絞り込みシートを表示する設定 ---
            .sheet(isPresented: $showingFilterSheet) {
                // ★★★ ここを修正: selectedCategory の引数を削除 ★★★
                FilterOptionsView(selectedPurpose: $selectedPurpose)
            }
            // --- 絞り込み条件が変わったらデータを再取得 ---
            .onChange(of: selectedPurpose) {
                Task {
                    await fetchFilteredQuestions()
                }
            }
            // 画面が最初に表示された時（だけ）データを取得
            .task {
                await fetchFilteredQuestions()
            }
            // 「下にスワイプ」で更新
            .refreshable {
                await fetchFilteredQuestions()
            }
        } // End NavigationStack
    } // End body

    // --- 絞り込み条件を使ってデータを取得する関数 ---
    private func fetchFilteredQuestions() async {
        let purposeToFetch = selectedPurpose.isEmpty ? nil : selectedPurpose

        // ★★★ ここを修正: category 引数を削除 ★★★
        await viewModel.fetchQuestions(purpose: purposeToFetch)
    }
}
