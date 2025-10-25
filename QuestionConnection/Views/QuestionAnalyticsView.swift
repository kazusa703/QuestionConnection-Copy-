import SwiftUI

struct QuestionAnalyticsView: View {
    // ViewModel and Auth state
    @StateObject private var viewModel = ProfileViewModel() // Create instance to fetch data
    @EnvironmentObject private var authViewModel: AuthViewModel

    // Question passed from ProfileView
    let question: Question

    var body: some View {
        Form { // Use Form for consistent styling with ProfileView
            Section("分析データ") {
                if viewModel.isAnalyticsLoading {
                    HStack {
                        Spacer()
                        ProgressView("読み込み中...")
                        Spacer()
                    }
                } else if let error = viewModel.analyticsError {
                    Text("エラー: \(error)")
                        .foregroundColor(.red)
                } else if let analytics = viewModel.analyticsResult {
                    HStack {
                        Text("総解答数")
                        Spacer()
                        Text("\(analytics.totalAnswers) 回")
                    }
                    HStack {
                        Text("正解数")
                        Spacer()
                        Text("\(analytics.correctAnswers) 回")
                    }
                    HStack {
                        Text("正解率")
                        Spacer()
                        // Format accuracy to one decimal place
                        Text(String(format: "%.1f %%", analytics.accuracy))
                    }
                } else {
                    // This case should ideally not happen if loading finishes correctly
                    Text("分析データを取得できませんでした。")
                        .foregroundColor(.secondary)
                }
            }

            Section("質問情報") {
                Text("タイトル: \(question.title)")
                Text("タグ: \(question.tags.joined(separator: ", "))")
                Text("備考: \(question.remarks.isEmpty ? "なし" : question.remarks)")
            }
        }
        .navigationTitle("問題の分析")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch analytics when the view appears
            fetchAnalytics()
        }
    }

    // Helper function to fetch analytics data
    private func fetchAnalytics() {
        guard let idToken = authViewModel.idToken else {
            viewModel.analyticsError = "認証情報が見つかりません。"
            return
        }
        Task {
            await viewModel.fetchQuestionAnalytics(questionId: question.questionId, idToken: idToken)
        }
    }
}
