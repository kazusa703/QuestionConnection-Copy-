import SwiftUI

/// DMスレッド一覧の「1行分」を表示するためのビュー
struct DMListRowView: View {
    // DMListViewから渡される情報
    let thread: Thread
    
    // 共有されたViewModelを受け取る
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @EnvironmentObject private var authViewModel: AuthViewModel

    // --- ★★★ ここから修正 ★★★ ---
    
    // State（状態）を削除し、Computed Property（計算プロパティ）に変更
    private var opponentNickname: String {
        guard let myUserId = authViewModel.userSub else { return "認証エラー" }
        
        // 相手のIDを特定
        guard let opponentId = thread.participants.first(where: { $0 != myUserId }) else {
            return "不明なユーザー"
        }
        
        // ニックネームVMのキャッシュを直接参照
        if let nickname = profileViewModel.userNicknames[opponentId] {
            // キャッシュに存在する（取得済み）
            return nickname.isEmpty ? "（未設定）" : nickname
        } else {
            // まだキャッシュにない（DMListViewが今まさに取得中）
            return "読み込み中..."
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // 相手のニックネームを表示（↑のopponentNicknameが使われる）
            Text("相手: \(opponentNickname)")
                .font(.headline)

            Text("Q: \(thread.questionTitle)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        // .task { ... } は削除する
    }
    
    // fetchOpponentNickname() 関数も削除する
    
    // --- ★★★ ここまで修正 ★★★ ---
}
