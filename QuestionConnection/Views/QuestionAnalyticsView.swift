import SwiftUI
import UIKit // ★ 統合: クリップボード機能(UIPasteboard)のために追加

struct QuestionAnalyticsView: View {
    // ★★★ @StateObject を @EnvironmentObject に変更 ★★★
    @EnvironmentObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    // ★★★ 追加: この画面を閉じるための dismiss ★★★
    @Environment(\.dismiss) private var dismiss

    // Question passed from ProfileView
    let question: Question
    
    // ★★★ 追加: 削除確認アラート用の State ★★★
    @State private var showingDeleteAlert = false

    var body: some View {
        Form { // Use Form for consistent styling
            
            // --- 分析データセクション ---
            Section("分析データ") {
                if viewModel.isAnalyticsLoading {
                    HStack {
                        Spacer()
                        ProgressView("読み込み中...")
                        Spacer()
                    }
                } else if let error = viewModel.analyticsError {
                    Text("エラー: \(error)")
                        .foregroundColor(.red)
                } else if let analytics = viewModel.analyticsResult {
                    HStack {
                        Text("総解答数")
                        Spacer()
                        Text("\(analytics.totalAnswers) 回")
                    }
                    HStack {
                        Text("正解数")
                        Spacer()
                        Text("\(analytics.correctAnswers) 回")
                    }
                    HStack {
                        Text("正解率")
                        Spacer()
                        Text(String(format: "%.1f %%", analytics.accuracy))
                    }
                } else {
                    Text("分析データを取得できませんでした。")
                        .foregroundColor(.secondary)
                }
            }

            // --- 質問情報セクション ---
            Section("質問情報") {
                Text("タイトル: \(question.title)")
                Text("タグ: \(question.tags.joined(separator: ", "))")
                
                if let purpose = question.purpose, !purpose.isEmpty {
                    Text("目的: \(purpose)")
                }
                
                if let code = question.shareCode, !code.isEmpty {
                    HStack {
                        Text("問題番号: \(code)")
                        Spacer()
                        Button {
                            // クリップボードにコピー
                            UIPasteboard.general.string = code
                        } label: {
                            Label("コピー", systemImage: "doc.on.doc")
                        }
                    }
                }
                
                Text("作成日時: \(question.createdAt)")
                Text("備考: \(question.remarks.isEmpty ? "なし" : question.remarks)")
            }

            // --- 削除ボタンセクション ---
            Section {
                Button(role: .destructive) {
                    // アラートを表示する
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer() // ViewModelが削除処理中ならインジケーター表示
                        if viewModel.isDeletingQuestion {
                            ProgressView()
                        } else {
                            Text("この質問を削除する")
                        }
                        Spacer()
                    }
                }
                // 削除処理中はボタンを無効化
                .disabled(viewModel.isDeletingQuestion)
            }

        } // End Form
        .navigationTitle("問題の分析")
        .navigationBarTitleDisplayMode(.inline)
        // ★ 統合: .onAppear と fetchAnalytics() 関数を、.task に置き換え
        .task {
             await viewModel.fetchQuestionAnalytics(questionId: question.questionId)
        }
        // ★★★ 追加: 削除確認アラートの設定 ★★★
        .alert("質問の削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                // 削除処理を実行
                Task {
                    let success = await viewModel.deleteQuestion(questionId: question.questionId)
                    // 成功したら画面を閉じる
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("「\(question.title)」を削除しますか？この操作は元に戻せません。")
        }
        // ★★★ (任意) 削除エラー表示用のアラート ★★★
        .alert("削除エラー", isPresented: .constant(viewModel.deletionError != nil), actions: {
            Button("OK") {
                viewModel.deletionError = nil // エラーメッセージをクリア
            }
        }, message: {
            Text(viewModel.deletionError ?? "不明なエラーが発生しました。")
        })
    } // End body

    // ★ 統合: .task を使用するため、このヘルパー関数は不要になりました
    // private func fetchAnalytics() { ... }
    
} // End struct
