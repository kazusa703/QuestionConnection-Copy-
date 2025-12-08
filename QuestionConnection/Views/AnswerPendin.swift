import SwiftUI

struct AnswerPendingView: View {
    let log: AnswerLogItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 待機中アイコン
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("採点待ち")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("出題者が記述式問題を採点中です。\nしばらくお待ちください。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(20)
            
            // 回答内容の表示
            VStack(alignment: .leading, spacing: 12) {
                Text("あなたの回答")
                        .font(.headline)
                    
                    ForEach(log.details.filter { $0.type == "essay" }) { detail in
                        VStack(alignment: .leading, spacing: 8) {
                            // ★ 問題文を表示
                            if let questionText = detail.questionText, !questionText.isEmpty {
                                Text("Q: \(questionText)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("記述式問題")
                                .font(.caption)
                                .foregroundColor(. secondary)
                            
                            Text(detail.userAnswer?.displayString ??  "(回答なし)")
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding()
            
            Spacer()
            
            // 質問情報
            if let questionTitle = log.questionTitle {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                    Text(questionTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal)
            }
            
            Button(action: { dismiss() }) {
                Text("閉じる")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("回答状況")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        // ★★★ 修正: プレビュー用のダミーデータを直接作成 ★★★
        AnswerPendingView(
            log: AnswerLogItem.previewSample
        )
    }
}

// ★★★ 追加: プレビュー用のサンプルデータ ★★★
extension AnswerLogItem {
    static var previewSample: AnswerLogItem {
        let json = """
        {
            "logId": "1",
            "userId": "user1",
            "status": "pending_review",
            "score": 0,
            "total": 3,
            "updatedAt": "2025-01-01",
            "details": [],
            "questionId": "q1",
            "questionTitle": "テスト質問"
        }
        """.data(using: .utf8)!
        
        return try! JSONDecoder().decode(AnswerLogItem.self, from: json)
    }
}
