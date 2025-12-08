import SwiftUI

struct MyQuestionsDetailView: View {
    let questions: [Question]
    let isLoadingMyQuestions: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // ★ 追加: タブ選択状態
    @State private var selectedTab = "essay" // "essay" (記述式あり), "choice" (選択/穴埋めのみ)
    
    var body: some View {
        VStack(spacing: 0) {
            // ★ 追加: 切り替えタブ (Picker)
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
                            // ★ タブによって遷移先を分岐
                            if selectedTab == "essay" {
                                // A. 記述式を含む -> 採点・管理画面 (AnswerManagementView) へ
                                NavigationLink(destination: AnswerManagementView(question: question).environmentObject(viewModel)) {
                                    QuestionRowView(question: question)
                                }
                            } else {
                                // B. 選択・穴埋めのみ -> 分析・詳細画面 (QuestionAnalyticsView) へ
                                NavigationLink(destination: QuestionAnalyticsView(question: question)
                                    .environmentObject(viewModel)
                                    .environmentObject(authViewModel)
                                ) {
                                    QuestionRowView(question: question)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain) // スタイルを維持
        }
        .navigationTitle("作成した問題")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    let authVM = AuthViewModel()
    let profileVM = ProfileViewModel(authViewModel: authVM)
    
    return NavigationStack {
        MyQuestionsDetailView(
            questions: [
                Question(questionId: "1", title: "記述式ありの質問", purpose: "test", tags: [], remarks: "", authorId: "me", quizItems: [QuizItem(id: "q1", type: .essay, questionText: "")], createdAt: "", dmInviteMessage: nil, shareCode: nil, answerCount: 5, pendingCount: 2),
                Question(questionId: "2", title: "選択式の質問", purpose: "test", tags: [], remarks: "", authorId: "me", quizItems: [QuizItem(id: "q2", type: .choice, questionText: "")], createdAt: "", dmInviteMessage: nil, shareCode: nil, answerCount: 10, pendingCount: 0)
            ],
            isLoadingMyQuestions: false,
            viewModel: profileVM
        )
        .environmentObject(authVM)
    }
}
