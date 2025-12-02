import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // ★ 追加: 課金管理
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @Environment(\.showAuthenticationSheet) private var showAuthenticationSheet

    @State private var originalNickname: String = ""
    
    // ユーザー情報セクションの開閉状態
    @State private var isUserInfoExpanded: Bool = false
    
    // 「自分が作成した質問」セクションの開閉状態
    @State private var isMyQuestionsExpanded: Bool = false
    
    // プロフィール画像関連
    @State private var showingImagePicker: Bool = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage: Bool = false
    
    // プロフィール画像のアラート表示用
    @State private var profileImageAlertMessage: String?
    @State private var showProfileImageAlert: Bool = false

    private var isNicknameChanged: Bool {
        viewModel.nickname != originalNickname
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) { // ★ VStackでラップ
                // ★★★ 追加: バナー広告 ★★★
                if !subscriptionManager.isPremium {
                    AdBannerView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                }
                
                if authViewModel.isSignedIn {
                    Form {
                        // --- ユーザー情報セクション ---
                        DisclosureGroup("ユーザー情報", isExpanded: $isUserInfoExpanded) {
                            // プロフィール画像
                            VStack(alignment: .center, spacing: 12) {
                                Text("プロフィール画像")
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 画像プレビュー
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let imageUrl = viewModel.userProfileImages[authViewModel.userSub ?? ""],
                                          let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                }
                                
                                // 画像選択ボタン + 残り変更回数表示
                                VStack(spacing: 8) {
                                    Button(action: { showingImagePicker = true }) {
                                        HStack {
                                            Spacer()
                                            if isUploadingImage {
                                                ProgressView()
                                                    .padding(.trailing, 8)
                                            } else {
                                                Image(systemName: "photo")
                                                    .padding(.trailing, 8)
                                            }
                                            Text(isUploadingImage ? "アップロード中..." : "画像を選択")
                                            Spacer()
                                        }
                                    }
                                    .disabled(isUploadingImage || viewModel.remainingProfileImageChanges <= 0)
                                    
                                    // 残り変更回数を表示
                                    HStack {
                                        Spacer()
                                        if viewModel.remainingProfileImageChanges > 0 {
                                            Text("残り変更回数: \(viewModel.remainingProfileImageChanges)/2")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("今月の変更回数が上限に達しました")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.vertical, 8)

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
                        DisclosureGroup("自分が作成した質問", isExpanded: $isMyQuestionsExpanded) {
                             if viewModel.isLoadingMyQuestions {
                                 HStack { Spacer(); ProgressView(); Spacer() }
                            } else if viewModel.myQuestions.isEmpty {
                                Text("まだ質問を作成していません。").foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.myQuestions) { question in
                                    NavigationLink(destination: destinationView(for: question)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(question.title).font(.headline)
                                                Text("タグ: \(question.tags.joined(separator: ", "))").font(.caption).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if question.hasEssayQuestion {
                                                Image(systemName: "pencil.and.list.clipboard").foregroundColor(.orange)
                                            } else {
                                                Image(systemName: "chart.bar").foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }

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
                    // --- ツールバー ---
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink {
                                SettingsView()
                                    .environmentObject(authViewModel)
                                    .environmentObject(subscriptionManager)
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                    // ImagePickerを表示
                    .sheet(isPresented: $showingImagePicker) {
                        ImagePicker(selectedImage: $selectedImage, onImageSelected: uploadProfileImage)
                    }
                    // プロフィール画像のアラート
                    .alert("プロフィール画像", isPresented: $showProfileImageAlert) {
                        Button("OK") { }
                    } message: {
                        Text(profileImageAlertMessage ?? "不明なエラー")
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
                }
            }
        } // End NavigationStack
    } // End body

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
    
    // プロフィール画像アップロード
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authViewModel.userSub else {
            profileImageAlertMessage = "認証情報がありません。"
            showProfileImageAlert = true
            return
        }
        
        selectedImage = image
        showingImagePicker = false
        isUploadingImage = true
        
        Task {
            await viewModel.uploadProfileImage(userId: userId, image: image)
            
            // アラートメッセージを表示
            if let alertMessage = viewModel.profileImageAlertMessage {
                profileImageAlertMessage = alertMessage
                showProfileImageAlert = true
            }
            
            // アップロード完了後に残り変更回数を更新
            await fetchRemainingProfileImageChanges(userId: userId)
            
            isUploadingImage = false
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
            
            // 残り変更回数を計算
            await fetchRemainingProfileImageChanges(userId: userId)
            
            originalNickname = viewModel.nickname
        }
    }
    
    // 残り変更回数を取得する関数
    private func fetchRemainingProfileImageChanges(userId: String) async {
        guard let idToken = await authViewModel.getValidIdToken() else { return }
        
        let url = viewModel.usersApiEndpoint.appendingPathComponent(userId)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(idToken, forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let profileImageChangeDates = json["profileImageChangeDates"] as? [String] {
                
                // 今月の変更回数をカウント
                let calendar = Calendar.current
                let now = Date()
                let currentMonth = calendar.dateComponents([.year, .month], from: now)
                
                let thisMonthCount = profileImageChangeDates.filter { dateStr in
                    if let date = ISO8601DateFormatter().date(from: dateStr) {
                        let dateComponents = calendar.dateComponents([.year, .month], from: date)
                        return dateComponents.year == currentMonth.year && dateComponents.month == currentMonth.month
                    }
                    return false
                }.count
                
                await MainActor.run {
                    viewModel.profileImageChangedCount = thisMonthCount
                    viewModel.remainingProfileImageChanges = max(0, 2 - thisMonthCount)
                }
            }
        } catch {
            print("Failed to fetch profile image change count: \(error)")
        }
    }

    private func resetLocalState() {
         viewModel.myQuestions = []
         viewModel.userStats = nil
         viewModel.analyticsResult = nil
         viewModel.nickname = ""
         originalNickname = ""
    }
    
    @ViewBuilder
    private func destinationView(for question: Question) -> some View {
        if question.hasEssayQuestion {
            AnswerManagementView(question: question).environmentObject(viewModel)
        } else {
            QuestionAnalyticsView(question: question).environmentObject(viewModel)
        }
    }
}

// ImagePicker コンポーネント
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
