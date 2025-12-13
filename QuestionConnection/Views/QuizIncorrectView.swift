import SwiftUI

struct QuizIncorrectView: View {
    let currentItem: QuizItem
    let userAnswer: [String: String]
    var onClose: (() -> Void)? = nil
    @EnvironmentObject var navManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                Text("不正解です ✗")
                    .font(. headline)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    . background(Color.green.opacity(0.1))
                    . cornerRadius(8)
                Divider()
                Text("あなたの回答:")
                    .font(.subheadline)
                    .fontWeight(. bold)
                let userAnswerText = getUserAnswerText()
                Text(userAnswerText)
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: . leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            Spacer()
            Button(action: {
                if let action = onClose {
                    action()
                } else {
                    navManager.popToRoot(tab: 0)
                    navManager.tabSelection = 0
                    dismiss()
                }
            }) {
                Text("終了")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.6)])
    }
    private func getCorrectAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            if !currentItem.choices.isEmpty {
                return currentItem.choices.first(where: { $0.id == currentItem.correctAnswerId })?.text ?? "N/A"
            }
            return "N/A"
        case .fillIn:
            if !currentItem.fillInAnswers.isEmpty {
                let sortedAnswers = currentItem.fillInAnswers.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
                return sortedAnswers.map { "(\($0.key)) \($0.value)" }.joined(separator: ", ")
            }
            return "N/A"
        case .essay:
            return currentItem.modelAnswer ?? "N/A"
        }
    }
    private func getUserAnswerText() -> String {
        switch currentItem.type {
        case .choice:
            let selectedId = userAnswer["choice"] ??  ""
            if !selectedId.isEmpty, !currentItem.choices.isEmpty {
                return currentItem.choices.first(where: { $0.id == selectedId })?.text ?? "未回答"
            }
            return "未回答"
        case .fillIn:
            let sortedKeys = userAnswer.keys.sorted { (Int($0) ?? 0) < (Int($1) ?? 0) }
            let answers = sortedKeys.compactMap { key -> String? in
                if let value = userAnswer[key], !value.isEmpty {
                    return "(\(key)) \(value)"
                }
                return nil
            }
            return answers.isEmpty ? "未回答" : answers.joined(separator: ", ")
        case .essay:
            return userAnswer["essay"] ?? "未回答"
        }
    }
}

#Preview {
    QuizIncorrectView(
        currentItem: QuizItem(id: "1", type: .choice, questionText: "テスト"),
        userAnswer: ["choice": "wrong"]
    )
}
