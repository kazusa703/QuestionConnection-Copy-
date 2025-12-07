import SwiftUI

struct SimpleQuestionsListView: View {
    let myQuestions: [Question]
    
    var body: some View {
        List {
            ForEach(myQuestions, id: \.questionId) { question in
                HStack {
                    VStack(alignment: .leading) {
                        Text(question.title)
                            .font(. headline)
                    }
                    Spacer()
                    
                    // ★ 未採点数を表示
                    if let pendingCount = question.pendingCount, pendingCount > 0 {
                        Text("未採点: \(pendingCount)")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}
