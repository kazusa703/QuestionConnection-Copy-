import Foundation

// DM送信時のペイロード
struct DM: Codable {
    let recipientId: String
    let senderId: String
    let questionTitle: String
    let messageText: String
    
    // メッセージタイプ（"text", "voice", "image"）
    var messageType: String? = "text"
    
    // ボイスメッセージ用
    var voiceBase64: String? = nil
    var voiceDuration: Double? = nil
    
    // 画像メッセージ用
    var imageBase64: String? = nil
}

// ★★★ 修正: Hashable を追加 ★★★
struct DMThread: Codable, Identifiable, Hashable {
    let threadId: String
    let participants: [String]
    let questionTitle: String
    let lastUpdated: String
    
    var id: String { threadId }
}

// ★★★ 修正: Hashable を追加 ★★★
struct Message: Codable, Identifiable, Hashable {
    let threadId: String
    let timestamp: String
    let messageId: String
    let senderId: String
    let text: String
    
    // タイプ拡張
    var messageType: String? = "text" // "text" | "voice" | "image"
    
    // ボイスメッセージ用（署名付きURLなど）
    var voiceUrl: String? = nil
    var voiceDuration: Double? = nil
    
    // 画像メッセージ用
    var imageUrl: String? = nil
    
    var id: String { messageId }
}
