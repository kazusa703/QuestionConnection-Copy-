import SwiftUI

/// ユーザーが最初にニックネームを設定するための画面
struct SetNicknameView: View {
    // 共有されたViewModelを受け取る
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // この画面（シート）を閉じるための機能
    @Environment(\.dismiss) private var dismiss
    
    // ニックネーム入力用の状態変数
    @State private var inputNickname: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("ようこそ！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("DMなどで表示されるニックネームを設定してください。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                TextField("ニックネーム", text: $inputNickname)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button(action: saveNickname) {
                    // ViewModelがローディング中ならインジケーターを表示
                    if profileViewModel.isNicknameLoading {
                        ProgressView()
                    } else {
                        Text("決定")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .disabled(inputNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || profileViewModel.isNicknameLoading) // 空欄またはローディング中は無効
                
                Spacer() // 上に寄せる
            }
            .padding(.top, 40) // 上部に少し余白
            .navigationTitle("ニックネーム設定")
            .navigationBarTitleDisplayMode(.inline)
            // ViewModelからのアラートを表示
            .alert("ニックネーム設定", isPresented: $profileViewModel.showNicknameAlert) {
                Button("OK") {
                    // 保存成功のアラートメッセージなら画面を閉じる
                    if profileViewModel.nicknameAlertMessage == "ニックネームを保存しました。" {
                        dismiss()
                    }
                }
            } message: {
                Text(profileViewModel.nicknameAlertMessage ?? "不明なエラー")
            }
        }
    }
    
    /// ニックネームを保存する関数
    private func saveNickname() {
        // 必要な情報（自分のID）を取得 (idToken を削除)
        guard let userId = authViewModel.userSub else {
            profileViewModel.nicknameAlertMessage = "認証情報が見つかりません。"
            profileViewModel.showNicknameAlert = true
            return
        }
        
        // キーボードを閉じる
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // ViewModelのupdateNicknameを呼び出す（@StateのinputNicknameを渡す）
        Task {
            // ★★★ ViewModelのnicknameプロパティを一時的に上書き ★★★
            profileViewModel.nickname = inputNickname
            // ★★★ idToken 引数を削除 ★★★
            await profileViewModel.updateNickname(userId: userId)
        }
    }
}

// --- プレビュー用のコード (修正) ---
#Preview {
    // initが変更されたことを想定し、ダミーのAuthViewModelを作成して渡す
    let authVM = AuthViewModel()
    let profileVM = ProfileViewModel(authViewModel: authVM) // init変更を想定
    
    return SetNicknameView()
        .environmentObject(authVM)
        .environmentObject(profileVM)
}

