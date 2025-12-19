import SwiftUI

// MARK: - 共通部品: 統一された穴番号ボックス (枠線付き長方形)
// 作成画面、回答画面、確認画面のすべてでこのコンポーネントを使用します。
struct FillInNumberBox: View {
    let number: Int
    // 必要に応じてサイズを微調整できるようにする（デフォルトは標準サイズ）
    var width: CGFloat = 80
    var height: CGFloat = 28
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(number)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .frame(width: width, height: height)
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - テキストパーツの構造体
struct TextPart: Identifiable {
    let id = UUID()
    let text: String
    let isHole: Bool
    let holeNumber: Int
}

// MARK: - [穴N] を [N] に変換するヘルパー関数
func convertOldHoleFormat(_ text: String) -> String {
    let pattern = "\\[穴(\\d+)\\]"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
    var result = text
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    for match in matches.reversed() {
        if let matchRange = Range(match.range, in: result),
           let numberRange = Range(match.range(at: 1), in: result) {
            let number = String(result[numberRange])
            result.replaceSubrange(matchRange, with: "[\(number)]")
        }
    }
    return result
}

// MARK: - 穴埋めテキスト表示用ビュー (統合版)
// 作成画面のプレビュー、回答画面、確認画面で使用
struct FillInQuestionTextOutlined: View {
    let text: String
    let font: Font
    
    init(text: String, font: Font = .headline) {
        self.text = convertOldHoleFormat(text)
        self.font = font
    }
    
    var body: some View {
        let parts = parseText(text)
        WrappingHStack(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 6) {
            ForEach(parts) { part in
                if part.isHole {
                    // ★ 統一コンポーネントを使用
                    FillInNumberBox(number: part.holeNumber)
                } else {
                    ForEach(splitTextForWrapping(part.text), id: \.self) { segment in
                        Text(segment)
                            .font(font)
                    }
                }
            }
        }
    }
    
    private func parseText(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        // [数字] または [穴数字] に対応
        let pattern = "\\[(穴?\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [TextPart(text: text, isHole: false, holeNumber: 0)]
        }
        
        var lastEnd = text.startIndex
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            if let matchRange = Range(match.range, in: text) {
                // 穴の前のテキスト
                if lastEnd < matchRange.lowerBound {
                    let beforeText = String(text[lastEnd..<matchRange.lowerBound])
                    if !beforeText.isEmpty {
                        parts.append(TextPart(text: beforeText, isHole: false, holeNumber: 0))
                    }
                }
                
                // 穴番号の抽出 ("穴1" -> 1, "1" -> 1)
                let matchString = String(text[matchRange])
                let numberString = matchString.trimmingCharacters(in: CharacterSet(charactersIn: "[]穴"))
                let number = Int(numberString) ?? 0
                
                parts.append(TextPart(text: "", isHole: true, holeNumber: number))
                lastEnd = matchRange.upperBound
            }
        }
        
        // 残りのテキスト
        if lastEnd < text.endIndex {
            let remainingText = String(text[lastEnd...])
            if !remainingText.isEmpty {
                parts.append(TextPart(text: remainingText, isHole: false, holeNumber: 0))
            }
        }
        
        return parts.isEmpty ? [TextPart(text: text, isHole: false, holeNumber: 0)] : parts
    }
    
    private func splitTextForWrapping(_ text: String) -> [String] {
        var segments: [String] = []
        var currentSegment = ""
        for char in text {
            if char == " " || char == "　" {
                if !currentSegment.isEmpty {
                    segments.append(currentSegment)
                    currentSegment = ""
                }
                segments.append(String(char))
            } else {
                currentSegment.append(char)
            }
        }
        if !currentSegment.isEmpty {
            segments.append(currentSegment)
        }
        return segments.isEmpty ? [text] : segments
    }
}

// MARK: - 折り返しレイアウト用 (変更なし)
struct WrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            if index < subviews.count {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                    proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
                )
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX)
        }
        let totalHeight = currentY + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
