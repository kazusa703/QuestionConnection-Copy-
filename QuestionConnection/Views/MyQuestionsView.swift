import SwiftUI

// プロフィール内で自分の問題一覧を表示するビュー
struct MyQuestionsView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel  // ★ 追加
    
    var body: some View {
        List {
            if profileViewModel.myQuestions.isEmpty {
                Text("作成した問題がありません")
                    .foregroundColor(.secondary)
            } else {
                ForEach(profileViewModel.myQuestions, id: \.questionId) { question in
                    NavigationLink(destination: AnswerManagementView(question: question).environmentObject(profileViewModel)) {
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
                                // ★ 回答数を表示
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    Text("\(question.answerCount ?? 0)")
                                        .font(.subheadline)
                                }
                                
                                // ★ 未採点数を表示（記述式がある場合のみ）
                                if question.hasEssayQuestion, let pendingCount = question.pendingCount, pendingCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark. circle.fill")
                                            .foregroundColor(.red)
                                        Text("未採点: \(pendingCount)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            . fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    . cornerRadius(4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("作成した問題")
        . task {
            // ★ authorId を渡す
            if let userSub = authViewModel.userSub {
                await profileViewModel.fetchMyQuestions(authorId: userSub)
            }
        }
    }
}
