import Foundation

// 問題の種類
enum QuizType: String, Codable {
    case choice = "choice"   // 選択式
    case fillIn = "fillIn"   // 穴埋め
    case essay = "essay"     // 記述式
}

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
    let shareCode: String?
    
    // ★★★ 追加: 回答数（DynamoDBの answerCount を受け取る）★★★
    var answerCount: Int?
    
    var id: String { questionId }
    
    // 記述式問題が含まれているか判定する便利プロパティ
    var hasEssayQuestion: Bool {
        quizItems.contains { $0.type == .essay }
    }
}

// 1問分のクイズ（変更なし）
struct QuizItem: Codable, Identifiable {
    let id: String
    var type: QuizType = .choice
    var questionText: String
    var choices: [Choice] = []
    var correctAnswerId: String = ""
    var fillInAnswers: [String: String] = [:]
    var modelAnswer: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case questionText
        case choices
        case correctAnswerId
        case fillInAnswers
        case modelAnswer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        questionText = try container.decode(String.self, forKey: .questionText)
        type = try container.decodeIfPresent(QuizType.self, forKey: .type) ?? .choice
        choices = try container.decodeIfPresent([Choice].self, forKey: .choices) ?? []
        correctAnswerId = try container.decodeIfPresent(String.self, forKey: .correctAnswerId) ?? ""
        fillInAnswers = try container.decodeIfPresent([String: String].self, forKey: .fillInAnswers) ?? [:]
        modelAnswer = try container.decodeIfPresent(String.self, forKey: .modelAnswer)
    }
    
    init(id: String, type: QuizType, questionText: String, choices: [Choice] = [], correctAnswerId: String = "", fillInAnswers: [String:String] = [:], modelAnswer: String? = nil) {
        self.id = id
        self.type = type
        self.questionText = questionText
        self.choices = choices
        self.correctAnswerId = correctAnswerId
        self.fillInAnswers = fillInAnswers
        self.modelAnswer = modelAnswer
    }
}

struct Choice: Codable, Identifiable {
    let id: String
    var text: String
}
