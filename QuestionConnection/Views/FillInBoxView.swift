import SwiftUI

// [穴N] を [N] に変換するヘルパー関数
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

// テキストパーツの構造体
struct TextPart: Identifiable {
    let id = UUID()
    let text: String
    let isHole: Bool
    let holeNumber: Int
}

// 作成画面用：青い正方形の穴ボックス（プレビュー用）
struct FillInBox: View {
    let number:  Int
    var body: some View {
        Text("(\(number))")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Color.blue)
            .cornerRadius(6)
    }
}

// 作成画面用：青い正方形の穴ボックス（正解入力エリア用）
struct FillInBoxSmall: View {
    let number: Int
    var body: some View {
        Text("(\(number))")
            .font(. caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 32, height:  32)
            .background(Color.blue)
            .cornerRadius(6)
    }
}

// 回答画面・確認画面用：枠線スタイルの穴ボックス（問題文内表示用）
struct FillInBoxOutlined: View {
    let number: Int
    var body:  some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(number)")
                .font(. caption)
                .fontWeight(. medium)
                .foregroundColor(.gray)
                .padding(. trailing, 8)
        }
        .frame(width: 80, height: 28)
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

// 回答画面・確認画面用：枠線スタイルの穴ボックス（回答ラベル用）
struct FillInAnswerBox: View {
    let number: Int
    var body:  some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(number)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(. gray)
                .padding(.trailing, 6)
        }
        .frame(width: 60, height: 28)
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

// 作成画面用：問題文を青い正方形ボックス付きで表示するView
struct FillInQuestionText: View {
    let text:  String
    let font: Font
    init(text: String, font: Font = .headline) {
        self.text = convertOldHoleFormat(text)
        self.font = font
    }
    var body: some View {
        let parts = parseText(text)
        WrappingHStack(alignment: . leading, horizontalSpacing: 4, verticalSpacing: 6) {
            ForEach(parts) { part in
                if part.isHole {
                    FillInBox(number: part.holeNumber)
                } else {
                    ForEach(splitTextForWrapping(part.text), id: \.self) { segment in
                        Text(segment)
                            .font(font)
                    }
                }
            }
        }
    }
    private func parseText(_ text:  String) -> [TextPart] {
        var parts: [TextPart] = []
        let pattern = "\\[(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [TextPart(text: text, isHole:  false, holeNumber: 0)]
        }
        var lastEnd = text.startIndex
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            if let matchRange = Range(match.range, in: text),
               let numberRange = Range(match.range(at: 1), in: text) {
                if lastEnd < matchRange.lowerBound {
                    let beforeText = String(text[lastEnd..<matchRange.lowerBound])
                    if !beforeText.isEmpty {
                        parts.append(TextPart(text:  beforeText, isHole: false, holeNumber: 0))
                    }
                }
                let number = Int(text[numberRange]) ?? 0
                parts.append(TextPart(text: "", isHole: true, holeNumber: number))
                lastEnd = matchRange.upperBound
            }
        }
        if lastEnd < text.endIndex {
            let remainingText = String(text[lastEnd...])
            if !remainingText.isEmpty {
                parts.append(TextPart(text:  remainingText, isHole:  false, holeNumber: 0))
            }
        }
        return parts.isEmpty ? [TextPart(text:  text, isHole: false, holeNumber: 0)] : parts
    }
    private func splitTextForWrapping(_ text:  String) -> [String] {
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

// 回答画面・確認画面用：問題文を枠線スタイルボックス付きで表示するView
struct FillInQuestionTextOutlined: View {
    let text: String
    let font: Font
    init(text:  String, font: Font = .headline) {
        self.text = convertOldHoleFormat(text)
        self.font = font
    }
    var body:  some View {
        let parts = parseText(text)
        WrappingHStack(alignment:  .leading, horizontalSpacing: 4, verticalSpacing:  6) {
            ForEach(parts) { part in
                if part.isHole {
                    FillInBoxOutlined(number: part.holeNumber)
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
        let pattern = "\\[(\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [TextPart(text: text, isHole: false, holeNumber: 0)]
        }
        var lastEnd = text.startIndex
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            if let matchRange = Range(match.range, in: text),
               let numberRange = Range(match.range(at: 1), in: text) {
                if lastEnd < matchRange.lowerBound {
                    let beforeText = String(text[lastEnd..<matchRange.lowerBound])
                    if !beforeText.isEmpty {
                        parts.append(TextPart(text: beforeText, isHole: false, holeNumber: 0))
                    }
                }
                let number = Int(text[numberRange]) ?? 0
                parts.append(TextPart(text: "", isHole: true, holeNumber: number))
                lastEnd = matchRange.upperBound
            }
        }
        if lastEnd < text.endIndex {
            let remainingText = String(text[lastEnd...])
            if !remainingText.isEmpty {
                parts.append(TextPart(text: remainingText, isHole: false, holeNumber: 0))
            }
        }
        return parts.isEmpty ? [TextPart(text: text, isHole:  false, holeNumber: 0)] : parts
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

// 折り返しレイアウト用のHStack
struct WrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 6
    func sizeThatFits(proposal:  ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds:  CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            if index < subviews.count {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                    proposal: ProposedViewSize(subviews[index].sizeThatFits(. unspecified))
                )
            }
        }
    }
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ??  . infinity
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
