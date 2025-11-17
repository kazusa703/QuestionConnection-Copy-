import Foundation

final class ThreadReadTracker {
    static let shared = ThreadReadTracker()
    private let defaults = UserDefaults.standard

    private func key(userId: String, threadId: String) -> String {
        return "lastSeen.\(userId).\(threadId)"
    }

    // 既読（閲覧）時刻を保存
    func markSeen(userId: String, threadId: String, date: Date = Date()) {
        defaults.set(date, forKey: key(userId: userId, threadId: threadId))
    }

    // 既読（閲覧）時刻を取得
    func lastSeen(userId: String, threadId: String) -> Date? {
        return defaults.object(forKey: key(userId: userId, threadId: threadId)) as? Date
    }

    // ★★★ 追加：未読に戻す ★★★
    func markAsUnread(userId: String, threadId: String) {
        // 既読時刻を削除することで、lastSeen が nil になり、未読判定が true になる
        defaults.removeObject(forKey: key(userId: userId, threadId: threadId))
    }

    // APIから返る lastUpdated(String) を Date に変換（ISO8601想定）
    private func parse(_ isoString: String) -> Date? {
        // ISO8601の一般的なケースをカバー
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: isoString) { return d }
        // 小数秒なしのパターン
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: isoString)
    }

    // 未読判定: lastUpdated > lastSeen で未読とみなす
    func isUnread(threadLastUpdated: String, userId: String, threadId: String) -> Bool {
        guard let updatedAt = parse(threadLastUpdated) else {
            // パースできない場合は未読表示はしない
            return false
        }
        if let seen = lastSeen(userId: userId, threadId: threadId) {
            return updatedAt > seen
        } else {
            // 一度も開いていなければ未読扱い
            return true
        }
    }
}
