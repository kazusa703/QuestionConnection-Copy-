import Foundation

struct Question: Codable, Identifiable {
    let questionId: String
    let title: String
    let purpose: String?
    let tags: [String]
    let remarks: String
    let authorId: String
    var quizItems: [QuizItem]
    let createdAt: String
    let dmInviteMessage: String?
    let shareCode: String?  // ★★★ デフォルト値を削除 ★★★
    
    var id: String { questionId }
    
    // ★★★ 追加：Decodable をカスタマイズ ★★★
    enum CodingKeys: String, CodingKey {
        case questionId
        case title
        case purpose
        case tags
        case remarks
        case authorId
        case quizItems
        case createdAt
        case dmInviteMessage
        case shareCode
    }
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
