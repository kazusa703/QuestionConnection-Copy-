import SwiftUI

struct BoardView: View {
    @StateObject private var viewModel = QuestionViewModel()
    // 認証情報
    @EnvironmentObject private var authViewModel: AuthViewModel

    // --- 絞り込み機能用の状態変数 ---
    @State private var showingFilterSheet = false
    @State private var selectedPurpose = "" // 「すべて」を空文字で表現
    @State private var showingOnlyBookmarks = false

    @State private var searchText = ""

    // 検索バー用の絞り込みロジック（タイトル/タグ/問題番号）
    private var filteredQuestions: [Question] {
        if searchText.isEmpty {
            return viewModel.questions
        } else {
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return viewModel.questions.filter { question in
                let titleMatch = question.title.localizedCaseInsensitiveContains(keyword)
                let tagMatch = question.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
                let codeMatch = (question.shareCode ?? "").localizedCaseInsensitiveContains(keyword)
                return titleMatch || tagMatch || codeMatch
            }
        }
    }

    // --- 絞り込みが適用されているかどうかの判定 ---
    private var isFilterActive: Bool {
        return !selectedPurpose.isEmpty || showingOnlyBookmarks
    }

    // --- 適用中の絞り込み条件を説明するテキスト ---
    private var activeFilterDescription: String {
        var descriptions: [String] = []
        if !selectedPurpose.isEmpty {
            descriptions.append("目的: \(selectedPurpose)")
        }
        if showingOnlyBookmarks {
            descriptions.append("ブックマークのみ")
        }
        return descriptions.joined(separator: ", ")
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
                            selectedPurpose = ""
                            showingOnlyBookmarks = false
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
                        NavigationLink(destination: QuestionDetailView(question: question)) {
                            VStack(alignment: .leading) {
                                Text(question.title)
                                    .font(.headline)
                                HStack(spacing: 6) {
                                    if let code = question.shareCode, !code.isEmpty {
                                        Text("#\(code)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.15))
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
            } // End VStack
            .navigationTitle("掲示板")
            .searchable(text: $searchText, prompt: "タイトル・タグ・番号で検索")
            // --- ツールバーに絞り込みボタン ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            // --- 絞り込みシート ---
            .sheet(isPresented: $showingFilterSheet) {
                FilterOptionsView(
                    selectedPurpose: $selectedPurpose,
                    showingOnlyBookmarks: $showingOnlyBookmarks
                )
            }
            // --- 絞り込み条件が変わったらデータを再取得 ---
            .onChange(of: selectedPurpose) {
                Task { await fetchFilteredQuestions() }
            }
            .onChange(of: showingOnlyBookmarks) {
                if authViewModel.isSignedIn {
                    Task { await fetchFilteredQuestions() }
                } else {
                    showingOnlyBookmarks = false
                }
            }
            // 初回ロード
            .task {
                viewModel.setAuthViewModel(authViewModel)
                await fetchFilteredQuestions()
            }
            // Pull to refresh
            .refreshable { await fetchFilteredQuestions() }
        } // End NavigationStack
    } // End body

    // --- データ取得 ---
    private func fetchFilteredQuestions() async {
        let purposeToFetch = selectedPurpose.isEmpty ? nil : selectedPurpose
        let bookmarkedByUserId: String? = (showingOnlyBookmarks && authViewModel.isSignedIn) ? authViewModel.userSub : nil
        await viewModel.fetchQuestions(purpose: purposeToFetch, bookmarkedBy: bookmarkedByUserId)
    }
}
