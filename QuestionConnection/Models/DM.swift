import Foundation

// --- 送信時に使うシンプルな構造体 ---
struct DM: Codable {
    let recipientId: String
    let senderId: String
    let questionTitle: String
    let messageText: String
}

// --- 「会話スレッド」を表すための設計図 ---
struct Thread: Codable, Identifiable, Hashable {
    let threadId: String
    let participants: [String]
    let questionTitle: String
    let lastUpdated: String

    // Identifiableプロトコルのための必須プロパティ
    var id: String { threadId }
}

// --- 「個々のメッセージ」を表すための設計図 ---
struct Message: Codable, Identifiable {
    let messageId: String
    let threadId: String
    let timestamp: String
    let senderId: String
    let text: String

    // Identifiableプロトコルのための必須プロパティ
    var id: String { messageId }
}
