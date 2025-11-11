import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    @State private var originalNickname: String = ""
    
    // ユーザー情報セクションの開閉状態
    @State private var isUserInfoExpanded: Bool = false
    
    // ★★★ 1.「自分が作成した質問」セクションの開閉状態を管理するStateを追加 ★★★
    @State private var isMyQuestionsExpanded: Bool = false

    private var isNicknameChanged: Bool {
        viewModel.nickname != originalNickname
    }

    var body: some View {
        NavigationStack {
            if authViewModel.isSignedIn {
                Form {
                    // --- ユーザー情報セクション (変更なし) ---
                    DisclosureGroup("ユーザー情報", isExpanded: $isUserInfoExpanded) {
                        // --- Email表示 ---
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

                        // --- ニックネーム入力 ---
                        HStack(alignment: .center) {
                            Text("ニックネーム")
                                .font(.callout)
                                .frame(width: 90, alignment: .leading)

                            TextField("DMなどで表示される名前", text: $viewModel.nickname)
                                .textFieldStyle(.roundedBorder)
                                .background(isNicknameChanged ? Color.yellow.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            if viewModel.isNicknameLoading {
                                ProgressView()
                                    .padding(.leading, 5)
                            } else {
                                Image(systemName: isNicknameChanged ? "pencil.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(isNicknameChanged ? .orange : .green)
                                    .padding(.leading, 5)
                            }
                        }

                        // --- ニックネーム保存ボタン ---
                        Button(action: saveNicknameAction) {
                            HStack {
                                Spacer()
                                Text(isNicknameChanged ? "変更を保存" : "保存済み")
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isNicknameLoading || !isNicknameChanged)

                    } // End DisclosureGroup (User Info)
                    .alert("プロフィール", isPresented: $viewModel.showNicknameAlert) {
                        Button("OK") { }
                    } message: {
                        Text(viewModel.nicknameAlertMessage ?? "不明なエラー")
                    }

                    // --- クイズ成績セクション (変更なし) ---
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

                    // ★★★ 2. 従来の Section を DisclosureGroup に変更 ★★★
                    DisclosureGroup("自分が作成した質問", isExpanded: $isMyQuestionsExpanded) {
                         if viewModel.isLoadingMyQuestions {
                             HStack { Spacer(); ProgressView(); Spacer() }
                        } else if viewModel.myQuestions.isEmpty {
                            Text("まだ質問を作成していません。").foregroundColor(.secondary)
                        } else {
                            // DisclosureGroup内でListを使うとインデントが深くなりすぎる場合があるため、
                            // Listを削除し、ForEachで直接リンクを表示します。
                            ForEach(viewModel.myQuestions) { question in
                                NavigationLink(destination: QuestionAnalyticsView(question: question).environmentObject(viewModel)) {
                                    VStack(alignment: .leading) {
                                        Text(question.title).font(.headline)
                                        Text("タグ: \(question.tags.joined(separator: ", "))").font(.caption).foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4) // Listのセルのような余白を追加
                                }
                            }
                        }
                    } // ★★★ End DisclosureGroup (My Questions) ★★★

                } // End Form
                .onAppear {
                    fetchProfileData()
                }
                .refreshable {
                    fetchProfileData()
                }
                .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
                     if !isSignedIn {
                          resetLocalState()
                     } else {
                         fetchProfileData()
                     }
                }
                // --- ツールバー (変更なし) ---
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                                            NavigationLink {
                                                SettingsView()
                                                    .environmentObject(authViewModel)
                                            } label: {
                                                Image(systemName: "gearshape")
                                            }
                    }
                }

            } else {
                // --- ゲストユーザー向けの表示 (変更なし) ---
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
            }
        } // End NavigationStack
    } // End body

    // (saveNicknameAction, fetchProfileData, resetLocalState 関数は変更なし)
    private func saveNicknameAction() {
            guard let userId = authViewModel.userSub else {
                viewModel.nicknameAlertMessage = "認証情報がありません。再ログインしてください。"
                viewModel.showNicknameAlert = true
                return
            }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            Task {
                await viewModel.updateNickname(userId: userId)
                if viewModel.nicknameAlertMessage == "ニックネームを保存しました。" {
                    originalNickname = viewModel.nickname
                }
            }
        }

        private func fetchProfileData() {
            guard authViewModel.isSignedIn,
                  let userId = authViewModel.userSub else { return }
            
            Task {
                async let fetchQuestionsTask: () = await viewModel.fetchMyQuestions(authorId: userId)
                async let fetchStatsTask: () = await viewModel.fetchUserStats(userId: userId)
                async let fetchNicknameTask: () = await viewModel.fetchMyProfile(userId: userId)
                
                _ = await [fetchQuestionsTask, fetchStatsTask, fetchNicknameTask]
                originalNickname = viewModel.nickname
            }
        }

        private func resetLocalState() {
             viewModel.myQuestions = []
             viewModel.userStats = nil
             viewModel.analyticsResult = nil
             viewModel.nickname = ""
             originalNickname = ""
        }
    
}
