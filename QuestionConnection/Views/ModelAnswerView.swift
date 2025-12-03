import SwiftUI

struct ModelAnswerView: View {
    let question: Question
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("記述式問題の模範解答")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    Text("以下の解答例を参考に、学習を進めましょう。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // 記述式問題のみを抽出して表示
                    ForEach(question.quizItems.filter { $0.type == .essay }) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("問題:")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            
                            Text(item.questionText)
                                .font(.body)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Text("模範解答:")
                                .font(.headline)
                                .foregroundColor(.green)
                                .padding(.top, 5)
                            
                            if let modelAnswer = item.modelAnswer, !modelAnswer.isEmpty {
                                Text(modelAnswer)
                                    .font(.body)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                Text("（模範解答は設定されていません）")
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical)
                        
                        Divider()
                    }
                    
                    if let remarks = question.remarks, !remarks.isEmpty {
                        Text("解説・備考:")
                            .font(.headline)
                        Text(remarks)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
