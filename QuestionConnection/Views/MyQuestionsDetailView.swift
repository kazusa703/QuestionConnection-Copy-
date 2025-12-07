import SwiftUI

struct MyQuestionsDetailView: View {
    let questions: [Question]
    let isLoadingMyQuestions: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        List {
            if isLoadingMyQuestions {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if questions.isEmpty {
                Text("作成した問題がありません")
                    .foregroundColor(.secondary)
            } else {
                ForEach(questions, id: \.questionId) { question in
                    NavigationLink(destination: AnswerManagementView(question: question).environmentObject(viewModel)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.title)
                                    .font(.headline)
                                
                                // タグ表示
                                if !question.tags.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(question.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                // ★★★ 修正：回答数と未採点数を同時表示 ★★★
                                HStack(spacing: 8) {
                                    // 緑：回答数
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                        Text("\(question.answerCount ?? 0)")
                                            .font(.subheadline)
                                    }
                                    
                                    // ★ 赤：未採点数（記述式がある場合のみ表示）
                                    if question.hasEssayQuestion, let pendingCount = question.pendingCount, pendingCount > 0 {
                                        Text("未採点: \(pendingCount)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("作成した問題")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let authVM = AuthViewModel()
    let profileVM = ProfileViewModel(authViewModel: authVM)
    
    return NavigationStack {
        MyQuestionsDetailView(
            questions: [],
            isLoadingMyQuestions: false,
            viewModel: profileVM
        )
        .environmentObject(authVM)
    }
}
