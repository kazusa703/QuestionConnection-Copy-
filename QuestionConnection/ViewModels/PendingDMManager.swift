import SwiftUI
import Combine

struct PendingDMItem: Identifiable, Hashable {
    let id: String
    let recipientId: String  // ★ 変更: DM相手のID
    let questionId: String
    let questionTitle: String
    let completedAt: String
    let role: PendingDMRole  // ★ 追加: 自分が回答者か出題者か
    
    // ★ 互換性のため authorId も残す
    var authorId: String { recipientId }
}

// ★★★ 追加: 役割を示すenum ★★★
enum PendingDMRole: String {
    case answerer = "answerer"  // 自分が回答者（相手は出題者）
    case author = "author"      // 自分が出題者（相手は回答者）
}

@MainActor
class PendingDMManager: ObservableObject {
    @Published var pendingDMs: [PendingDMItem] = []
    @Published var isLoading = false
    
    /// 未送信DM一覧を取得（新API）
    func fetchPendingDMs(
        myUserId: String,
        myAnswersLogs: [AnswerLogItem],      // 自分が回答したログ
        authorAnswersLogs: [AnswerLogItem],  // 自分の質問への回答ログ
        dmThreads: [DMThread]
    ) {
        isLoading = true
        
        // すでに会話している相手のIDリストを作る
        let chattingUserIds = Set(dmThreads.flatMap { $0.participants })
        
        var pendingItems: [PendingDMItem] = []
        var processedUserIds = Set<String>()
        
        // ========================================
        // 1. 回答者として：全問正解/承認済みの回答
        // ========================================
        let qualifiedAsAnswerer = myAnswersLogs.filter { log in
            let isAllCorrect = (log.score == log.total && log.total > 0)
            return isAllCorrect || log.status == "approved" || log.status == "completed"
        }
        
        for answer in qualifiedAsAnswerer {
            guard let authorId = answer.authorId else { continue }
            
            // 自分自身は除外
            if authorId == myUserId { continue }
            
            // すでに会話中の相手は除外
            if chattingUserIds.contains(authorId) { continue }
            
            // 同じ相手は1回だけ
            if processedUserIds.contains(authorId) { continue }
            processedUserIds.insert(authorId)
            
            let item = PendingDMItem(
                id: "answerer_\(answer.logId)",
                recipientId: authorId,
                questionId: answer.questionId,
                questionTitle: answer.questionTitle ?? "無題",
                completedAt: answer.updatedAt,
                role: .answerer
            )
            pendingItems.append(item)
        }
        
        // ========================================
        // 2. 出題者として：正解にした回答者
        // ========================================
        let qualifiedAsAuthor = authorAnswersLogs.filter { log in
            // 承認済み（正解にした）回答のみ
            return log.status == "approved"
        }
        
        for answer in qualifiedAsAuthor {
            let respondentId = answer.userId
            
            // 自分自身は除外
            if respondentId == myUserId { continue }
            
            // すでに会話中の相手は除外
            if chattingUserIds.contains(respondentId) { continue }
            
            // 同じ相手は1回だけ
            if processedUserIds.contains(respondentId) { continue }
            processedUserIds.insert(respondentId)
            
            let item = PendingDMItem(
                id: "author_\(answer.logId)",
                recipientId: respondentId,
                questionId: answer.questionId,
                questionTitle: answer.questionTitle ?? "無題",
                completedAt: answer.updatedAt,
                role: .author
            )
            pendingItems.append(item)
        }
        
        // 日付順にソート（新しい順）
        pendingItems.sort { $0.completedAt > $1.completedAt }
        
        self.pendingDMs = pendingItems
        isLoading = false
    }
    
    // ★★★ 既存の関数も維持（互換性のため）★★★
    func fetchPendingDMs(
        myUserId: String,
        answersLogs: [AnswerLogItem],
        dmThreads: [DMThread]
    ) {
        fetchPendingDMs(
            myUserId: myUserId,
            myAnswersLogs: answersLogs,
            authorAnswersLogs: [],
            dmThreads: dmThreads
        )
    }
    
    var hasPendingDMs: Bool {
        !pendingDMs.isEmpty
    }
    
    var pendingCount: Int {
        pendingDMs.count
    }
}
