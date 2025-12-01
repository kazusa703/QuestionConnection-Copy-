import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // ★★★ 修正: SubscriptionManager に変更 ★★★
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @Environment(\.dismiss) private var dismiss

    let question: Question

    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [String: Any] = [:] // 回答保存用
    @State private var isResultView = false
    
    // 記述式用の入力
    @State private var essayInput: String = ""
    // 穴埋め用の入力
    @State private var fillInInputs: [String: String] = [:]
    
    private let adManager = InterstitialAdManager()

    var body: some View {
        VStack {
            if isResultView {
                QuizResultView(
                    question: question,
                    userAnswers: userAnswers,
                    dismissAction: { dismiss() }
                )
            } else {
                // --- 問題表示エリア ---
                let item = question.quizItems[currentQuestionIndex]
                
                VStack(alignment: .leading, spacing: 20) {
                    // 進捗バー
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(question.quizItems.count))
                    
                    Text("Q\(currentQuestionIndex + 1). \(itemTypeString(item.type))")
                        .font(.headline).foregroundColor(.secondary)
                    
                    Text(item.questionText) // 穴埋めならここで変換表示が必要
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // --- 回答エリア (タイプ別) ---
                    if item.type == .choice {
                        ForEach(item.choices) { choice in
                            Button {
                                submitAnswer(choice.id)
                            } label: {
                                Text(choice.text).frame(maxWidth: .infinity).padding()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if item.type == .fillIn {
                        // 穴ごとの入力欄を表示
                        ScrollView {
                            ForEach(Array(item.fillInAnswers.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading) {
                                    Text(key)
                                    TextField("回答を入力", text: Binding(
                                        get: { fillInInputs[key] ?? "" },
                                        set: { fillInInputs[key] = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                }
                                .padding(.bottom)
                            }
                        }
                        Button("回答する") {
                            submitAnswer(fillInInputs) // 辞書を渡す
                        }
                        .buttonStyle(.borderedProminent)
                        
                    } else if item.type == .essay {
                        TextEditor(text: $essayInput)
                            .border(Color.gray.opacity(0.3))
                            .frame(height: 200)
                        
                        Button("回答を送信") {
                            submitAnswer(essayInput)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(essayInput.isEmpty)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("クイズ")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.setAuthViewModel(authViewModel)
            // ★★★ 修正: 変数名変更 ★★★
            if !subscriptionManager.isPremium {
                adManager.loadAd()
            }
        }
    }
    
    func itemTypeString(_ type: QuizType) -> String {
        switch type {
        case .choice: return "選択問題"
        case .fillIn: return "穴埋め問題"
        case .essay: return "記述問題"
        }
    }
    
    // 回答送信処理
    func submitAnswer(_ answer: Any) {
        // 回答を保存
        let itemId = question.quizItems[currentQuestionIndex].id
        userAnswers[itemId] = answer
        
        // ログ送信（サーバーへ）
        // ※記述式の場合は正誤判定はここでは行わない（Pending）
        // 既存のlogAnswerを拡張するか、一旦ローカル保持する設計
        
        // 次へ
        if currentQuestionIndex + 1 < question.quizItems.count {
            currentQuestionIndex += 1
            // 入力リセット
            essayInput = ""
            fillInInputs = [:]
        } else {
            // 全問終了 -> 結果画面へ
            finishQuiz()
        }
    }
    
    func finishQuiz() {
        // ★★★ 修正: 変数名変更 ★★★
        if subscriptionManager.isPremium {
            isResultView = true
        } else {
            // 無料会員なら広告を表示してから結果へ
            adManager.showAd {
                isResultView = true
            }
        }
    }
}

// 結果画面（簡易版）
struct QuizResultView: View {
    let question: Question
    let userAnswers: [String: Any]
    var dismissAction: () -> Void
    
    var hasEssay: Bool {
        question.quizItems.contains { $0.type == .essay }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("回答終了！").font(.largeTitle)
            
            if hasEssay {
                Text("記述式問題が含まれているため、作成者の採点待ちとなります。")
                Text("採点完了後に通知が届きます。")
                    .foregroundColor(.secondary)
            } else {
                // 選択・穴埋めのみなら即判定ロジックを表示
                // (既存の正誤判定ロジックをここに移植)
                Text("お疲れ様でした。")
            }
            
            Button("閉じる") {
                dismissAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
