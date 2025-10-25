import SwiftUI

// 絞り込み条件を選択するためのシートビュー
struct FilterOptionsView: View {
    // BoardViewから渡される選択中の条件
    @Binding var selectedPurpose: String
    
    // ViewModelから選択肢リストを取得
    @StateObject private var viewModel = QuestionViewModel() // availablePurposes を使うため残す
    
    // このシートを閉じるための機能
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // --- 目的で絞り込むセクション ---
                Section(header: Text("目的で絞り込む")) {
                    Picker("目的を選択", selection: $selectedPurpose) {
                        Text("すべて").tag("") // 「すべて」を表す空タグ
                        ForEach(viewModel.availablePurposes, id: \.self) { purpose in
                            Text(purpose).tag(purpose)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // --- リセットボタンセクション ---
                Section {
                    Button(role: .destructive) {
                        selectedPurpose = ""
                        dismiss() // シートを閉じる
                    } label: {
                        Text("絞り込みをリセット")
                    }
                }
            } // End Form
            .navigationTitle("絞り込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss() // シートを閉じる
                    }
                }
            }
        } // End NavigationStack
    } // End body
} // End struct FilterOptionsView

// --- ★★★ プレビュー用のコード ★★★ ---
#Preview {
    // @State 変数をラッパー構造体の中で宣言する
    struct PreviewWrapper: View {
        @StateObject var authVM = AuthViewModel() // Use @StateObject for preview VM
        @State var dummyShowingSheet = true

        var body: some View {
            // ConfirmationViewに渡す引数を修正
            ConfirmationView(showingAuthSheet: $dummyShowingSheet, email: "test@example.com")
                .environmentObject(authVM)
        }
    }

    return PreviewWrapper() // ラッパービューを返す
}
