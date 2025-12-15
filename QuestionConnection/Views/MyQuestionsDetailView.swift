import SwiftUI

struct MyQuestionsDetailView: View {
    let questions: [Question]
    let isLoadingMyQuestions: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // タブ選択状態
    @State private var selectedTab = "essay"
    
    // ★★★ 追加: 削除用のState ★★★
    @State private var questionToDelete: Question?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 切り替えタブ (Picker)
            Picker("Filter", selection: $selectedTab) {
                Text("記述式を含む").tag("essay")
                Text("選択・穴埋め").tag("choice")
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemBackground))
            
            // リスト表示
            List {
                if isLoadingMyQuestions {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else {
                    // タブに合わせてフィルタリング
                    let filteredQuestions = questions.filter { question in
                        if selectedTab == "essay" {
                            return question.hasEssayQuestion
                        } else {
                            return !question.hasEssayQuestion
                        }
                    }
                    
                    if filteredQuestions.isEmpty {
                        Text("該当する問題はありません")
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                            .padding(.top, 20)
                    } else {
                        ForEach(filteredQuestions, id: \.questionId) { question in
                            // タブによって遷移先を分岐
                            if selectedTab == "essay" {
                                NavigationLink(destination: AnswerManagementView(question: question).environmentObject(viewModel)) {
                                    QuestionRowView(question: question)
                                }
                                // ★★★ 追加: 長押しメニュー ★★★
                                .contextMenu {
                                    Button(role: .destructive) {
                                        questionToDelete = question
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            } else {
                                NavigationLink(destination: QuestionAnalyticsView(question: question)
                                    .environmentObject(viewModel)
                                    .environmentObject(authViewModel)
                                ) {
                                    QuestionRowView(question: question)
                                }
                                // ★★★ 追加: 長押しメニュー ★★★
                                .contextMenu {
                                    Button(role: .destructive) {
                                        questionToDelete = question
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("作成した問題")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        // ★★★ 追加: 削除確認アラート ★★★
        .alert("本当に削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {
                questionToDelete = nil
            }
            Button("削除", role: .destructive) {
                Task {
                    await deleteQuestion()
                }
            }
        } message: {
            if let question = questionToDelete {
                Text("「\(question.title)」を削除します。この操作は取り消せません。")
            }
        }
        // ★★★ 追加: 削除完了アラート ★★★
        .alert("削除完了", isPresented: $showDeleteSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("問題を削除しました。")
        }
        // ★★★ 追加: 削除中のオーバーレイ ★★★
        .overlay {
            if isDeleting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("削除中...")
                        .font(.subheadline)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
    }
    
    // ★★★ 追加: 削除処理 ★★★
    private func deleteQuestion() async {
        guard let question = questionToDelete else { return }
        
        isDeleting = true
        
        let success = await viewModel.deleteQuestion(questionId: question.questionId)
        
        isDeleting = false
        questionToDelete = nil
        
        if success {
            showDeleteSuccess = true
        }
    }
}
