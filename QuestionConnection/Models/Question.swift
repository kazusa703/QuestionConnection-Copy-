import Foundation

// 投稿全体を表す設計図
struct Question: Codable, Identifiable {
    let questionId: String
    let title: String
    // ★★★ purposeをtagsの前に移動 ★★★
    let purpose: String?
    let tags: [String]
    let remarks: String
    let authorId: String
    var quizItems: [QuizItem]
    let createdAt: String
    
    // Identifiableプロトコルに準拠するため、idプロパティを定義
    var id: String { questionId }
}

// 1問分のクイズを表す設計図 (変更なし)
struct QuizItem: Codable, Identifiable {
    let id: String
    var questionText: String
    var choices: [Choice]
    var correctAnswerId: String
}

// 選択肢を表す設計図 (変更なし)
struct Choice: Codable, Identifiable {
    let id: String
    var text: String
}



