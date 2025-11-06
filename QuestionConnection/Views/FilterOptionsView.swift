import SwiftUI

// 絞り込み条件を選択するためのシートビュー
struct FilterOptionsView: View {
    // BoardViewから渡される選択中の条件
    @Binding var selectedPurpose: String
    // ★★★ 追加: BoardViewから渡されるブックマークフィルターの状態 ★★★
    @Binding var showingOnlyBookmarks: Bool

    // ViewModelから選択肢リストを取得 (変更なし)
    @StateObject private var viewModel = QuestionViewModel()

    // このシートを閉じるための機能 (変更なし)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // --- 目的で絞り込むセクション (変更なし) ---
                Section(header: Text("目的で絞り込む")) {
                    Picker("目的を選択", selection: $selectedPurpose) {
                        Text("すべて").tag("")
                        ForEach(viewModel.availablePurposes, id: \.self) { purpose in
                            Text(purpose).tag(purpose)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // ★★★ 追加: ブックマークで絞り込むセクション ★★★
                Section(header: Text("ブックマーク")) {
                    Toggle("ブックマークした質問のみ表示", isOn: $showingOnlyBookmarks)
                }
                // ★★★ ここまで追加 ★★★

                // --- リセットボタンセクション ---
                Section {
                    Button(role: .destructive) {
                        selectedPurpose = ""
                        // ★★★ 追加: ブックマークフィルターもリセット ★★★
                        showingOnlyBookmarks = false
                        dismiss() // シートを閉じる
                    } label: {
                        Text("絞り込みをリセット")
                    }
                }
            } // End Form
            .navigationTitle("絞り込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { // (完了ボタンは変更なし)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        } // End NavigationStack
    } // End body
} // End struct FilterOptionsView

// --- プレビュー用のコード (修正) ---
#Preview {
    // プレビュー用にダミーのBindingを作成
    struct PreviewWrapper: View {
        @State var dummyPurpose = ""
        @State var dummyBookmarkFilter = false // ダミーの状態

        var body: some View {
            // FilterOptionsViewにダミーのBindingを渡す
            FilterOptionsView(
                selectedPurpose: $dummyPurpose,
                showingOnlyBookmarks: $dummyBookmarkFilter // ダミーを渡す
            )
            // 必要ならダミーのViewModelも渡す (今回は不要)
        }
    }
    return PreviewWrapper()
}
