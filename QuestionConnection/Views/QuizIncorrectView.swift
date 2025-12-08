import SwiftUI

struct QuizIncorrectView: View {
    let currentItem: QuizItem
    let userAnswer: [String: String]
    // ★★★ 追加: 記述式があるかどうかのフラグ ★★★
    let hasEssay: Bool
    @EnvironmentObject var navManager: NavigationManager
       @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("不正解です ✗")
                    .font(.headline)
            }
            .padding(20)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("正解:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                let correctAnswer = getCorrectAnswerText()
                Text(correctAnswer)
                    .font(.body)
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                
                Divider()
                
                Text("あなたの回答:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                let userAnswerText = getUserAnswerText()
                Text(userAnswerText)
                    .font(.body)
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            
            Spacer()
            
            // ★★★ 追加: 記述式がある場合のメッセージ ★★★
            if hasEssay {
                Text("※ 入力済みの記述式回答は作成者に送信され、採点されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
            }
            
            Button(action: { dismiss() }) {
                Text("終了")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.65)]) // 少し高さを広げました
    }
    
    // ... (getCorrectAnswerText, getUserAnswerText は変更なし) ...
    private func getCorrectAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            if !currentItem.choices.isEmpty {
                return currentItem.choices.first(where: { $0.id == currentItem.correctAnswerId })?.text ?? "N/A"
            }
            return "N/A"
        case .fillIn:
            if !currentItem.fillInAnswers.isEmpty {
                return currentItem.fillInAnswers.values.joined(separator: ", ")
            }
            return "N/A"
        case .essay:
            return currentItem.modelAnswer ?? "N/A"
        }
    }
    
    private func getUserAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            let selectedId = userAnswer["choice"] ?? ""
            if !selectedId.isEmpty, !currentItem.choices.isEmpty {
                return currentItem.choices.first(where: { $0.id == selectedId })?.text ?? "未回答"
            }
            return "未回答"
        case .fillIn:
            let values = userAnswer.values.filter { !$0.isEmpty }
            return values.isEmpty ? "未回答" : values.joined(separator: ", ")
        case .essay:
            return userAnswer["essay"] ?? "未回答"
        }
    }
}

#Preview {
    QuizIncorrectView(
        currentItem: QuizItem(id: "1", type: .choice, questionText: "テスト"),
        userAnswer: ["choice": "wrong"],
        hasEssay: true
    )
}
