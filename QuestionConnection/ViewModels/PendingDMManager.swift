import SwiftUI
import Combine

struct PendingDMItem: Identifiable, Hashable {
    let id: String
    let authorId: String
    let questionId: String
    let questionTitle: String
    let completedAt: String
}

@MainActor
class PendingDMManager: ObservableObject {
    @Published var pendingDMs: [PendingDMItem] = []
    @Published var isLoading = false
    
    func fetchPendingDMs(
        myUserId: String,
        answersLogs: [AnswerLogItem],
        dmThreads: [DMThread]
    ) {
        isLoading = true
        
        // 1. 全問正解または承認済みの回答を抽出
        let qualifiedAnswers = answersLogs.filter { log in
            let isAllCorrect = (log.score == log.total && log.total > 0)
            return isAllCorrect || log.status == "approved" || log.status == "completed"
        }
        
        // 2. すでに会話している相手のIDリストを作る
        let chattingUserIds = Set(dmThreads.flatMap { $0.participants })
        
        // 3. DM未送信リストを作成
        var pendingItems: [PendingDMItem] = []
        var processedAuthorIds = Set<String>()
        
        for answer in qualifiedAnswers {
            guard let authorId = answer.authorId else { continue }
            
            // 自分自身は除外
            if authorId == myUserId { continue }
            
            // すでに会話中の相手は除外
            if chattingUserIds.contains(authorId) { continue }
            
            // 同じ出題者は1回だけ（最新の問題のみ）
            if processedAuthorIds.contains(authorId) { continue }
            processedAuthorIds.insert(authorId)
            
            let item = PendingDMItem(
                id: answer.logId,
                authorId: authorId,
                questionId: answer.questionId,
                questionTitle: answer.questionTitle ?? "無題",
                completedAt: answer.updatedAt
            )
            pendingItems.append(item)
        }
        
        // 日付順にソート（新しい順）
        pendingItems.sort { $0.completedAt > $1.completedAt }
        
        self.pendingDMs = pendingItems
        isLoading = false
    }
    
    var hasPendingDMs: Bool {
        !pendingDMs.isEmpty
    }
    
    var pendingCount: Int {
        pendingDMs.count
    }
}
