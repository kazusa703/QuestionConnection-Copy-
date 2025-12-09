import SwiftUI

struct AnswerResultView: View {
    let log: AnswerLogItem
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var dmViewModel: DMViewModel
    @State private var navigateToDM = false
    @State private var createdThread: DMThread?
    @State private var showModelAnswer = false
    
    // 質問詳細データ（メッセージ表示用）
    @State private var questionDetail: Question?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // ヘッダー: 結果表示
                HStack {
                    if log.status == "approved" {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                        Text("正解！承認されました").font(.title2).bold().foregroundColor(.green)
                    } else if log.status == "rejected" {
                        Image(systemName: "xmark.seal.fill").foregroundColor(.red)
                        Text("不正解").font(.title2).bold().foregroundColor(.red)
                    } else {
                        Image(systemName: "hourglass").foregroundColor(.orange)
                        Text("採点待ち").font(.title2).bold().foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // 回答内容の表示
                Text("あなたの回答").font(.headline)
                
                ForEach(log.details) { detail in
                    VStack(alignment: .leading, spacing: 8) {
                        if let questionText = detail.questionText, !questionText.isEmpty {
                            Text("Q: \(questionText)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Text(detail.type == "essay" ? "記述式" : (detail.type == "choice" ? "選択式" : "穴埋め"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(detail.userAnswer?.displayString ?? "(回答なし)")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(detail.isCorrect ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                            .cornerRadius(8)
                        
                        HStack {
                            Image(systemName: detail.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(detail.isCorrect ? .green : .red)
                            Text(detail.isCorrect ? "正解" : "不正解")
                                .font(.caption)
                                .foregroundColor(detail.isCorrect ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2)
                }
                
                Divider()
                
                // --- アクションエリア ---
                if log.status == "approved" {
                    VStack(spacing: 16) {
                        // ★★★ 追加: 作成者からのメッセージ表示 ★★★
                        if let message = questionDetail?.dmInviteMessage, !message.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("作成者からのメッセージ", systemImage: "quote.bubble.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(message)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        
                        // 正解 → DMへ
                        Button(action: startDM) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("メッセージを送る")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                } else if log.status == "rejected" {
                    // 不正解 → 模範解答
                    Button(action: fetchModelAnswer) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("模範解答を見る")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("回答結果")
        // ★★★ 追加: 画面表示時に質問データを取得（メッセージ表示のため） ★★★
        .task {
            // 承認済み、かつデータ未取得の場合のみ取得しに行く
            if log.status == "approved" && questionDetail == nil {
                await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
                await MainActor.run {
                    self.questionDetail = profileViewModel.selectedQuestionForModelAnswer
                }
            }
        }
        .sheet(isPresented: $showModelAnswer) {
            if let q = questionDetail {
                ModelAnswerView(question: q)
            } else {
                ProgressView()
            }
        }
        .navigationDestination(isPresented: $navigateToDM) {
            if let thread = createdThread {
                ConversationView(thread: thread, viewModel: dmViewModel)
            }
        }
    }
    
    func startDM() {
        Task {
            if let authorId = log.authorId,
               let thread = await dmViewModel.findDMThread(with: authorId) {
                await MainActor.run {
                    self.createdThread = thread
                    self.navigateToDM = true
                }
            } else {
                // スレッドが見つからない場合（新規作成）の処理
                // 必要であれば sendInitialDM などを呼び出す画面へ遷移
                // ここでは簡易的にフォールバック
                print("既存のDMスレッドが見つかりませんでした")
            }
        }
    }
    
    func fetchModelAnswer() {
        showModelAnswer = true
        Task {
            // すでに取得済みなら再利用
            if questionDetail == nil {
                await profileViewModel.fetchQuestionDetailForModelAnswer(questionId: log.questionId)
                await MainActor.run {
                    self.questionDetail = profileViewModel.selectedQuestionForModelAnswer
                }
            }
        }
    }
}
