import Foundation

// MARK: - Quiz Types

enum QuizType: String, Codable {
    case choice = "choice"
    case fillIn = "fillIn"
    case essay = "essay"
}

// MARK: - Question

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
    var answerCount: Int?
    var pendingCount: Int?
    
    var id: String { questionId }
    var hasEssayQuestion: Bool { quizItems.contains { $0.type == .essay } }
}

struct QuizItem: Codable, Identifiable {
    let id: String
    var type: QuizType = .choice
    var questionText: String
    var choices: [Choice] = []
    var correctAnswerId: String = ""
    var fillInAnswers: [String: String] = [:]
    var modelAnswer: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, type, questionText, choices, correctAnswerId, fillInAnswers, modelAnswer
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
    
    init(id: String, type: QuizType, questionText: String, choices: [Choice] = [], correctAnswerId: String = "", fillInAnswers: [String: String] = [:], modelAnswer: String? = nil) {
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

// MARK: - DM

struct DM: Codable {
    let recipientId: String
    let senderId: String
    let questionTitle: String
    let messageText: String
    var messageType: String? = "text"
    var voiceBase64: String? = nil
    var voiceDuration: Double? = nil
    var imageBase64: String? = nil
}

struct DMThread: Codable, Identifiable, Hashable {
    let threadId: String
    let participants: [String]
    let questionTitle: String
    let lastUpdated: String
    var id: String { threadId }
}

struct Message: Codable, Identifiable, Hashable {
    let threadId: String
    let timestamp: String
    let messageId: String
    let senderId: String
    let text: String
    var messageType: String? = "text"
    var voiceUrl: String? = nil
    var voiceDuration: Double? = nil
    var imageUrl: String? = nil
    var id: String { messageId }
}
