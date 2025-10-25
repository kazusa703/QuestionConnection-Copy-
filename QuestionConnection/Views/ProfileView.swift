import SwiftUI

struct ProfileView: View {
    // ★★★ 修正: @StateObject を @EnvironmentObject に変更 ★★★
    @EnvironmentObject private var viewModel: ProfileViewModel
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                // --- ログイン済みユーザー向けの表示 ---
                Form {
                    // --- ユーザー情報セクション ---
                    Section(header: Text("ユーザー情報")) {
                        HStack {
                            Text("Email")
                                .font(.callout)
                                .frame(width: 90, alignment: .leading)
                            Spacer()
                            Text(authViewModel.userEmail ?? "読み込み中...")
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        HStack(alignment: .center) {
                            Text("ニックネーム")
                                .font(.callout)
                                .frame(width: 90, alignment: .leading)
                            
                            TextField("DMなどで表示される名前", text: $viewModel.nickname)
                                .textFieldStyle(.roundedBorder)
                            
                            if viewModel.isNicknameLoading {
                                ProgressView()
                                    .padding(.leading, 5)
                            }
                        }
                        
                        Button(action: {
                            guard let userId = authViewModel.userSub, let idToken = authViewModel.idToken else {
                                viewModel.nicknameAlertMessage = "認証情報がありません。再ログインしてください。"
                                viewModel.showNicknameAlert = true
                                return
                            }
                            // キーボードを閉じる
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            Task {
                                await viewModel.updateNickname(userId: userId, idToken: idToken)
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("ニックネームを保存")
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isNicknameLoading)
                    }
                    .alert("プロフィール", isPresented: $viewModel.showNicknameAlert) {
                        Button("OK") { }
                    } message: {
                        Text(viewModel.nicknameAlertMessage ?? "不明なエラー")
                    }
                    
                    // --- クイズ成績セクション ---
                    Section(header: Text("クイズ成績")) {
                        if viewModel.isLoadingUserStats {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        } else if let stats = viewModel.userStats {
                            HStack { Text("総回答数"); Spacer(); Text("\(stats.totalAnswers) 問") }
                            HStack { Text("正解数"); Spacer(); Text("\(stats.correctAnswers) 問") }
                            HStack { Text("正解率"); Spacer(); Text(String(format: "%.1f %%", stats.accuracy)) }
                        } else {
                            Text("成績データがありません。").foregroundColor(.secondary)
                        }
                    }

                    // --- 自分が作成した質問セクション ---
                    Section(header: Text("自分が作成した質問")) {
                         if viewModel.isLoadingMyQuestions {
                             HStack { Spacer(); ProgressView(); Spacer() }
                        } else if viewModel.myQuestions.isEmpty {
                            Text("まだ質問を作成していません。").foregroundColor(.secondary)
                        } else {
                            List(viewModel.myQuestions) { question in
                                NavigationLink(destination: QuestionAnalyticsView(question: question)) {
                                    VStack(alignment: .leading) {
                                        Text(question.title).font(.headline)
                                        Text("タグ: \(question.tags.joined(separator: ", "))").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    // --- ログアウトボタンセクション ---
                    Section {
                        Button(role: .destructive) {
                            authViewModel.signOut()
                        } label: {
                            Text("ログアウト")
                        }
                    }
                } // End Form
                .navigationTitle("プロフィール")
                .onAppear {
                    // ログイン時のみデータを取得
                    fetchProfileData()
                }
                .refreshable {
                    // ログイン時のみデータを取得
                    fetchProfileData()
                }
                .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
                     if !isSignedIn {
                          viewModel.myQuestions = []
                          viewModel.userStats = nil
                          viewModel.analyticsResult = nil
                          viewModel.nickname = ""
                     }
                }

            } else {
                // --- ゲストユーザー向けの表示 ---
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("プロフィール機能を利用するにはログインが必要です。")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Button("ログイン / 新規登録") {
                        showAuthenticationSheet.wrappedValue = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("プロフィール")
            }
        } // End NavigationStack
    } // End body

    // fetchProfileData (変更なし)
    private func fetchProfileData() {
        guard authViewModel.isSignedIn,
              let userId = authViewModel.userSub,
              let idToken = authViewModel.idToken else { return }
        
        Task {
            // 3つの非同期処理を並行して実行
            async let fetchQuestionsTask: () = await viewModel.fetchMyQuestions(authorId: userId)
            async let fetchStatsTask: () = await viewModel.fetchUserStats(userId: userId)
            async let fetchNicknameTask: () = await viewModel.fetchMyProfile(userId: userId, idToken: idToken)
            
            // すべての完了を待つ
            _ = await [fetchQuestionsTask, fetchStatsTask, fetchNicknameTask]
        }
    }
}
