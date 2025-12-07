import SwiftUI

struct EssayQuestionView: View {
    let item: QuizItem
    @Binding var answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("あなたの回答:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $answer)
                .frame(minHeight: 150)
                . padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text("※ 入力した内容は出題者に送られます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    EssayQuestionView(
        item: QuizItem(id: "1", type: .essay, questionText: "説明してください"),
        answer: . constant("")
    )
}
