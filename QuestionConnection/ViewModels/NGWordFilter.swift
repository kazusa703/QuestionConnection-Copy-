import Foundation

/// NGワードフィルター
final class ContentFilter {
    
    static let shared = ContentFilter()
    
    private init() {}
    
    // MARK: - NGワードリスト
    
    /// 完全一致でブロックするワード
    private let exactMatchWords:  Set<String> = [
        "死ね", "殺す", "殺すぞ",
        "振り込め", "口座教えて", "暗証番号",
        "LINE交換", "カカオ交換", "会いたい", "会おう",
        "ホテル", "ラブホ",
        "住所教えて", "電話番号教えて", "本名教えて",
    ]
    
    /// 部分一致でブロックするワード
    private let partialMatchWords: [String] = [
        "ころす", "しね", "くたばれ", "ボケ", "カス", "クズ",
        "ゴミ", "きもい", "キモい", "うざい", "ウザい",
        "バカ", "ばか", "アホ", "あほ",
        "ガイジ", "池沼", "障害者",
        "チョン", "シナ",
        "セックス", "SEX", "エッチ", "えっち",
        "おっぱい", "ちんこ", "まんこ", "射精",
        "裸", "ヌード", "nude",
        "LINE", "ライン", "らいん",
        "カカオ", "インスタ", "Twitter", "X交換",
        "電話番号", "メアド", "メールアドレス",
        "振込", "入金", "送金", "お金貸して",
        "儲かる", "稼げる", "副業",
        "大麻", "覚醒剤", "コカイン", "ドラッグ",
        "クスリ売", "薬売",
    ]
    
    /// 正規表現パターン
    private let regexPatterns: [String] = [
        "0[789]0[-]?\\d{4}[-]?\\d{4}",
        "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
        "@[a-zA-Z0-9_]{3,}",
        "line\\.me",
    ]
    
    // MARK: - チェックメソッド
    
    func check(_ text: String) -> ContentFilterResult {
        let normalizedText = normalize(text)
        
        for word in exactMatchWords {
            if normalizedText == normalize(word) {
                return . blocked(reason: "不適切な表現が含まれています")
            }
        }
        
        for word in partialMatchWords {
            if normalizedText.contains(normalize(word)) {
                return . blocked(reason: "不適切な表現が含まれています")
            }
        }
        
        for pattern in regexPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: . caseInsensitive) {
                let range = NSRange(normalizedText.startIndex..., in: normalizedText)
                if regex.firstMatch(in: normalizedText, options: [], range: range) != nil {
                    return .blocked(reason: "個人情報や連絡先の投稿は禁止されています")
                }
            }
        }
        
        return .allowed
    }
    
    func checkMultiple(_ texts: [String]) -> ContentFilterResult {
        for text in texts {
            let result = check(text)
            if case .blocked = result {
                return result
            }
        }
        return . allowed
    }
    
    // MARK: - Private Methods
    
    private func normalize(_ text: String) -> String {
        var result = text.lowercased()
        result = result.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? result
        result = result.applyingTransform(.hiraganaToKatakana, reverse: true) ?? result
        result = result.replacingOccurrences(of:  " ", with: "")
        result = result.replacingOccurrences(of: "　", with: "")
        result = result.replacingOccurrences(of:  ".", with: "")
        result = result.replacingOccurrences(of: "。", with: "")
        result = result.replacingOccurrences(of: "-", with: "")
        result = result.replacingOccurrences(of: "_", with:  "")
        return result
    }
}

// MARK: - チェック結果

enum ContentFilterResult {
    case allowed
    case blocked(reason:  String)
    
    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }
    
    var isBlocked: Bool {
        !isAllowed
    }
    
    var message: String?  {
        if case .blocked(let reason) = self {
            return reason
        }
        return nil
    }
}
