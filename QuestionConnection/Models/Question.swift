import Foundation

// 投稿全体を表す設計図
struct Question: Codable, Identifiable {
    let questionId: String
    let title: String
    // purpose は任意
    let purpose: String?
    let tags: [String]
    let remarks: String
    let authorId: String
    var quizItems: [QuizItem]
    let createdAt: String

    // 追加フィールド（デフォルト nil を付けて、初期化を緩くする）
    let dmInviteMessage: String? = nil    // サーバーが返す場合のみ入る
    let shareCode: String? = nil          // 問題番号（シェアコード）

    // Identifiable
    var id: String { questionId }
}

// 1問分のクイズ
struct QuizItem: Codable, Identifiable {
    let id: String
    var questionText: String
    var choices: [Choice]
    var correctAnswerId: String
}

// 選択肢
struct Choice: Codable, Identifiable {
    let id: String
    var text: String
}
