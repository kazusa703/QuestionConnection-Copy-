import Foundation
import Combine
// API呼び出し自体はURLSessionを使うため、AWSClientRuntime は不要です

// (UserStats, QuestionAnalyticsResult, BookmarkResponse, BlocklistResponse 構造体は変更なし)
struct UserStats: Codable {
    let totalAnswers: Int
    let correctAnswers: Int
    let accuracy: Double
}
struct QuestionAnalyticsResult: Codable {
    let totalAnswers: Int
    let correctAnswers: Int
    let accuracy: Double
}

// ★★★ 1. UserProfile に notifyOnDM を追加 ★★★
struct UserProfile: Codable {
    let nickname: String?
    let notifyOnCorrectAnswer: Bool? // 通知設定
    let notifyOnDM: Bool? // ★ DM通知設定 (追加)
}
struct BookmarkResponse: Decodable {
    let bookmarks: [String] // もしキー名が違うならここを修正
}
struct BlocklistResponse: Decodable {
    let blockedUserIds: [String]
}


@MainActor
class ProfileViewModel: ObservableObject {

    // (myQuestions ... isLoadingSettings までのプロパティは変更なし)
    @Published var myQuestions: [Question] = []
    @Published var userStats: UserStats?
    @Published var isLoadingMyQuestions = false
    @Published var isLoadingUserStats = false
    @Published var analyticsResult: QuestionAnalyticsResult?
    @Published var isAnalyticsLoading = false
    @Published var analyticsError: String?
    @Published var nickname: String = ""
    @Published var isNicknameLoading = false
    @Published var nicknameAlertMessage: String?
    @Published var showNicknameAlert = false
    
    // (blockedUserIds ... isLoadingSettings までのプロパティは変更なし)
    @Published var blockedUserIds: Set<String> = []
    @Published var isLoadingBlocklist = false
    @Published var bookmarkedQuestionIds: Set<String> = []
    @Published var isLoadingBookmarks = false
    @Published var isDeletingQuestion = false
    @Published var deletionError: String?
    
    // (notifyOnCorrectAnswer は変更なし)
    @Published var notifyOnCorrectAnswer: Bool = false
    // ★★★ 2. DM通知用の設定変数を追加 ★★★
    @Published var notifyOnDM: Bool = false
    
    @Published var isLoadingSettings: Bool = false


    // (キャッシュ戦略 ... 変更なし)
    @Published var userNicknames: [String: String] = [:] // キャッシュ
    private var inFlightNicknameTasks: [String: Task<String, Never>] = [:] // 進行中のタスク
    private var failedAt: [String: Date] = [:] // 失敗記録
    private let retryCooldown: TimeInterval = 60 // 60秒のクールダウン


    // (apiEndpoint, authViewModel, init ... 変更なし)
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!
    private let questionsApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    private let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        Task {
            if authViewModel.isSignedIn {
                await fetchBookmarks()
                await fetchBlocklist()
                // ★★★ ログイン時に「保留中のトークン」がないか確認する処理を追加 ★★★
                await checkAndRegisterPendingDeviceToken()
            }
        }
    }

    // (deleteQuestion ... registerDeviceToken までの関数は変更なし)
    func deleteQuestion(questionId: String) async -> Bool {
        guard authViewModel.isSignedIn, !isDeletingQuestion else { return false }
        isDeletingQuestion = true
        deletionError = nil
        print("質問削除開始: \(questionId)")
        let url = questionsApiEndpoint.appendingPathComponent(questionId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("質問削除: 認証トークン取得失敗")
                deletionError = "認証情報がありません。再ログインしてください。"
                isDeletingQuestion = false
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                print("質問削除APIエラー: \(response)")
                deletionError = "質問の削除に失敗しました (サーバーエラー)。"
                isDeletingQuestion = false
                return false
            }
            print("質問削除API成功: \(questionId)")
            myQuestions.removeAll { $0.questionId == questionId }
            isDeletingQuestion = false
            return true
        } catch {
            print("質問削除APIリクエストエラー: \(error)")
            deletionError = "質問の削除中にエラーが発生しました: \(error.localizedDescription)"
            isDeletingQuestion = false
            return false
        }
    }
    func fetchBookmarks() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBookmarks else { return }
        isLoadingBookmarks = true
        print("ブックマークリストの取得開始...")
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク取得: 認証トークン取得失敗")
                isLoadingBookmarks = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ブックマーク取得APIエラー: \(response)")
                isLoadingBookmarks = false
                return
            }
            let responseData = try JSONDecoder().decode(BookmarkResponse.self, from: data)
            self.bookmarkedQuestionIds = Set(responseData.bookmarks)
            print("ブックマークリスト取得完了。件数: \(bookmarkedQuestionIds.count)")
        } catch {
            print("ブックマーク取得APIリクエストエラー: \(error)")
        }
        isLoadingBookmarks = false
    }
    func addBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        let (wasInserted, _) = bookmarkedQuestionIds.insert(questionId)
        guard wasInserted else {
             print("ブックマーク追加: 既にローカルに存在 \(questionId)")
             return
        }
        print("ブックマーク追加 (ローカル): \(questionId)")
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク追加: 認証トークン取得失敗")
                bookmarkedQuestionIds.remove(questionId)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let requestBody = ["questionId": questionId]
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("ブックマーク追加APIエラー: \(response)")
                bookmarkedQuestionIds.remove(questionId)
                return
            }
            print("ブックマーク追加API成功: \(questionId)")
        } catch {
            print("ブックマーク追加APIリクエストエラー: \(error)")
            bookmarkedQuestionIds.remove(questionId)
        }
    }
    func removeBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard bookmarkedQuestionIds.contains(questionId) else {
             print("ブックマーク削除: ローカルに存在しない \(questionId)")
             return
        }
        bookmarkedQuestionIds.remove(questionId)
        print("ブックマーク削除 (ローカル): \(questionId)")
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks").appendingPathComponent(questionId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク削除: 認証トークン取得失敗")
                bookmarkedQuestionIds.insert(questionId)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                print("ブックマーク削除APIエラー: \(response)")
                bookmarkedQuestionIds.insert(questionId)
                return
            }
            print("ブックマーク削除API成功: \(questionId)")
        } catch {
            print("ブックマーク削除APIリクエストエラー: \(error)")
            bookmarkedQuestionIds.insert(questionId)
        }
    }
    func isBookmarked(questionId: String) -> Bool {
        return bookmarkedQuestionIds.contains(questionId)
    }
    func handleSignIn() {
        Task {
            await fetchBookmarks()
            await fetchBlocklist()
            await checkAndRegisterPendingDeviceToken() // ★ サインイン時にも呼び出す
        }
    }
    func handleSignOut() {
        bookmarkedQuestionIds = []
        blockedUserIds = []
        myQuestions = []
        userStats = nil
        userNicknames = [:]
        failedAt = [:]
        inFlightNicknameTasks.values.forEach { $0.cancel() }
        inFlightNicknameTasks = [:]
        print("ローカルの全キャッシュと進行中タスクをクリアしました。")
    }
    
    // ★★★ "deviceToken" (単数形) を呼び出すように修正済み ★★★
    func registerDeviceToken(deviceTokenString: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else {
            print("デバイストークン登録: 未ログインのためスキップ")
            return
        }
        print("デバイストークンをサーバーに登録開始...")
        
        // ★★★ "deviceToken" (単数形) になっていることを確認！ ★★★
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("deviceToken")
        
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("デバイストークン登録: 認証トークン取得失敗")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let requestBody = ["deviceToken": deviceTokenString]
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            // ★ POST/PUT の成功は 200 (OK) または 201 (Created) が一般的
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("デバイストークン登録APIエラー: \(response)")
                return
            }
            print("デバイストークン登録に成功しました。")
            
        } catch {
            print("デバイストークン登録APIリクエストエラー: \(error)")
        }
    }

    // ★★★ 新しい関数を追加 ★★★
    /// UserDefaults に保留中のデバイストークンがあれば登録する
    func checkAndRegisterPendingDeviceToken() async {
        if let token = UserDefaults.standard.string(forKey: "pendingDeviceToken") {
            print("保留中のデバイストークンが見つかりました。登録を試みます...")
            
            // 自分の registerDeviceToken 関数を呼び出す
            await registerDeviceToken(deviceTokenString: token)
            
            // 処理が成功したかどうかにかかわらず、
            // サーバーへの登録を「試行」したので、保留中トークンは削除する
            UserDefaults.standard.removeObject(forKey: "pendingDeviceToken")
            print("保留中のデバイストークンを処理しました。")
        }
    }
    
    // (fetchNickname, requestNicknameFromAPI ... 変更なし)
    func fetchNickname(userId: String) async -> String {
        if let cached = userNicknames[userId] {
            print("ニックネーム(ID: \(userId))をキャッシュから取得: \(cached)")
            return cached.isEmpty ? "（未設定）" : cached // ★ UI表示用に変換
        }
        if let lastFailed = failedAt[userId], Date().timeIntervalSince(lastFailed) < retryCooldown {
            print("ニックネーム(ID: \(userId)): クールダウン中のためスキップ")
            return "(削除されたユーザー)" // ★ UI表示用に変換
        }
        if let task = inFlightNicknameTasks[userId] {
            print("ニックネーム(ID: \(userId)): 進行中のタスクを待機")
            let name = await task.value
            return name.isEmpty ? "(削除されたユーザー)" : name // ★ UI表示用に変換
        }
        guard !userId.isEmpty else { return "不明" }
        let task = Task<String, Never> { [weak self] in
            guard let self else { return "" }
            let name = await self.requestNicknameFromAPI(userId: userId)
            return name ?? ""
        }
        inFlightNicknameTasks[userId] = task
        print("ニックネーム(ID: \(userId)): 新規タスク開始")
        let name = await task.value
        self.userNicknames[userId] = name
        inFlightNicknameTasks.removeValue(forKey: userId)
        if name.isEmpty {
            print("ニックネーム(ID: \(userId)): 取得結果が空のため失敗として記録")
            failedAt[userId] = Date()
            return name.isEmpty ? "(削除されたユーザー)" : name
        } else {
            failedAt.removeValue(forKey: userId)
            return name // ★ UI表示用に変換
        }
    }
    func warmFetchNicknames(for userIds: Set<String>) {
        for uid in userIds {
            if userNicknames[uid] == nil, inFlightNicknameTasks[uid] == nil {
                Task {
                    _ = await fetchNickname(userId: uid)
                }
            }
        }
    }
    private func requestNicknameFromAPI(userId: String) async -> String? {
        guard !userId.isEmpty else { return nil }
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ニックネーム取得(API): 認証トークン取得失敗")
            return nil
        }
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ニックネーム取得(API)時にサーバーエラー(ID: \(userId)): \(response)")
                return nil // ★ 失敗時は nil
            }
            guard let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
                print("ニックネーム取得(API): 200 OK だがプロファイル内容がデコード不可 (削除ユーザー？) ID: \(userId)")
                return nil // ★ 失敗時は nil
            }
            return profile.nickname
        } catch {
            print("ニックネーム取得(API)へのリクエスト中にエラー(ID: \(userId)): \(error)")
            return nil // ★ 失敗時は nil
        }
    }


    // ★★★ 3. fetchMyProfile に notifyOnDM を追加 ★★★
    func fetchMyProfile(userId: String) async {
        guard !userId.isEmpty else { return }
        isLoadingSettings = true
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("プロファイル取得: 認証トークン取得失敗")
            isLoadingSettings = false
            return
        }
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("プロファイル取得時にサーバーエラー(ID: \(userId)): \(response)")
                isLoadingSettings = false
                return
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.nickname = profile.nickname ?? ""
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false
            self.notifyOnDM = profile.notifyOnDM ?? false // ★ 追加
            userNicknames[userId] = profile.nickname ?? ""
        } catch {
            print("プロファイル取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }
    
    // (updateNickname は変更なし)
    func updateNickname(userId: String) async {
        guard !userId.isEmpty else { return }
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ニックネーム更新: 認証トークン取得失敗")
            nicknameAlertMessage = "認証情報がありません。再ログインしてください。"
            showNicknameAlert = true
            return
        }
        let nicknameToSave = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        isNicknameLoading = true
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            let payload = ["nickname": nicknameToSave]
            let jsonData = try JSONEncoder().encode(payload)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ニックネーム更新時にサーバーエラー: \(response)")
                nicknameAlertMessage = "ニックネームの保存に失敗しました。"
                showNicknameAlert = true
                isNicknameLoading = false
                return
            }
            print("ニックネームの更新に成功しました！")
            nicknameAlertMessage = "ニックネームを保存しました。"
            showNicknameAlert = true
            userNicknames[userId] = nicknameToSave
        } catch {
            print("ニックネーム更新APIへのリクエスト中にエラー: \(error)")
            nicknameAlertMessage = "エラーが発生しました: \(error.localizedDescription)"
            showNicknameAlert = true
        }
        isNicknameLoading = false
    }
    
    // ★★★ 4. fetchNotificationSettings に notifyOnDM を追加 ★★★
    func fetchNotificationSettings() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("通知設定取得: 認証トークン取得失敗")
            isLoadingSettings = false
            return
        }
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("通知設定取得時にサーバーエラー(ID: \(userId)): \(response)")
                isLoadingSettings = false
                return
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false
            self.notifyOnDM = profile.notifyOnDM ?? false // ★ 追加
        } catch {
            print("通知設定取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }

    // (updateNotificationSetting は変更なし)
    func updateNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        print("通知設定(正解)を更新: \(isOn)") // ★ ログを明確化
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("settings")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("通知設定更新: 認証トークン取得失敗")
                isLoadingSettings = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            // ★ "notifyOnCorrectAnswer" キーで送信
            let requestBody = ["notifyOnCorrectAnswer": isOn]
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("通知設定更新APIエラー: \(response)")
                self.notifyOnCorrectAnswer = !isOn // 失敗したら元に戻す
                isLoadingSettings = false
                return
            }
            print("通知設定(正解)の更新に成功しました。")
            isLoadingSettings = false
        } catch {
            print("通知設定更新APIリクエストエラー: \(error)")
            self.notifyOnCorrectAnswer = !isOn // 失敗したら元に戻す
            isLoadingSettings = false
        }
    }
    
    // ★★★ 5. DM通知設定を更新する新しい関数を追加 ★★★
    func updateDMNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        print("通知設定(DM)を更新: \(isOn)") // ★ ログを明確化
        
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("settings")
        
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("通知設定(DM)更新: 認証トークン取得失敗")
                isLoadingSettings = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            // ★ "notifyOnDM" キーで送信
            let requestBody = ["notifyOnDM": isOn]
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("通知設定(DM)更新APIエラー: \(response)")
                self.notifyOnDM = !isOn // 失敗したら元に戻す
                isLoadingSettings = false
                return
            }
            print("通知設定(DM)の更新に成功しました。")
            isLoadingSettings = false
        } catch {
            print("通知設定(DM)更新APIリクエストエラー: \(error)")
            self.notifyOnDM = !isOn // 失敗したら元に戻す
            isLoadingSettings = false
        }
    }
    
    // (deleteAccount ... 変更なし)
    func deleteAccount() async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else {
            print("ProfileViewModel: 未ログインのためアカウント削除を実行できません。")
            return false
        }
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ProfileViewModel: 認証トークン取得失敗")
            return false
        }
        let urlString = "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users/\(userId)"
        guard let url = URL(string: urlString) else {
            print("ProfileViewModel: アカウント削除URLが無効です。")
            return false
        }
        print("アカウント削除APIを呼び出します: \(urlString)")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) else {
                print("アカウント削除APIエラー: \(response)")
                return false
            }
            print("アカウント削除API成功。")
            return true
        } catch {
            print("アカウント削除APIリクエストエラー: \(error)")
            return false
        }
    }
    func reportContent(targetId: String, targetType: String, reason: String, detail: String) async -> Bool {
        guard authViewModel.isSignedIn else {
            print("ProfileViewModel: 未ログインのため通報できません。")
            return false
        }
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ProfileViewModel: 認証トークン取得失敗 (通報)")
            return false
        }
        let urlString = "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/reports"
        guard let url = URL(string: urlString) else {
            print("ProfileViewModel: 通報URLが無効です。")
            return false
        }
        print("通報APIを呼び出します: \(targetType) \(targetId)")
        let requestBody: [String: String] = [
            "targetType": targetType,
            "targetId": targetId,
            "reason": reason,
            "detail": detail
        ]
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("通報APIエラー: \(response)")
                return false
            }
            print("通報API成功。Report ID: \(String(data: data, encoding: .utf8) ?? "")")
            return true
        } catch {
            print("通報APIリクエストエラー: \(error)")
            return false
        }
    }
    func fetchBlocklist() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBlocklist else { return }
        isLoadingBlocklist = true
        print("ブロックリストの取得開始...")
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("blocklist")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブロックリスト取得: 認証トークン取得失敗")
                isLoadingBlocklist = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ブロックリスト取得APIエラー: 不正なレスポンス (HTTPURLResponseではありません)")
                isLoadingBlocklist = false
                return
            }
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8) ?? "(ボディなし)"
                print("ブロックリスト取得APIエラー: Status \(httpResponse.statusCode). Body: \(responseBody)")
                isLoadingBlocklist = false
                return
            }
            let responseData = try JSONDecoder().decode(BlocklistResponse.self, from: data)
            self.blockedUserIds = Set(responseData.blockedUserIds)
            print("ブロックリスト取得完了。件数: \(blockedUserIds.count)")
        } catch {
            print("ブロックリスト取得APIリクエストエラー: \(error)")
        }
        isLoadingBlocklist = false
    }
    func addBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        let (wasInserted, _) = blockedUserIds.insert(blockedUserId)
        guard wasInserted else {
             print("ブロック追加: 既にローカルに存在 \(blockedUserId)")
             return true
        }
        print("ブロック追加 (ローカル): \(blockedUserId)")
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("block")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブロック追加: 認証トークン取得失敗")
                blockedUserIds.remove(blockedUserId)
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let requestBody = ["blockedUserId": blockedUserId]
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("ブロック追加APIエラー: \(response)")
                blockedUserIds.remove(blockedUserId)
                return false
            }
            print("ブロック追加API成功: \(blockedUserId)")
            return true
        } catch {
            print("ブロック追加APIリクエストエラー: \(error)")
            blockedUserIds.remove(blockedUserId)
            return false
        }
    }
    func removeBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        guard blockedUserIds.contains(blockedUserId) else {
             print("ブロック解除: ローカルに存在しない \(blockedUserId)")
             return true
        }
        blockedUserIds.remove(blockedUserId)
        print("ブロック解除 (ローカル): \(blockedUserId)")
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("block").appendingPathComponent(blockedUserId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブロック解除: 認証トークン取得失敗")
                blockedUserIds.insert(blockedUserId)
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                print("ブロック解除APIエラー: \(response)")
                blockedUserIds.insert(blockedUserId)
                return false
            }
            print("ブロック解除API成功: \(blockedUserId)")
            return true
        } catch {
            print("ブロック解除APIリクエストエラー: \(error)")
            blockedUserIds.insert(blockedUserId)
            return false
        }
    }
    func isBlocked(userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    
    // --- ★★★ ここが修正された関数 ★★★ ---
    func fetchMyQuestions(authorId: String) async {
        guard !authorId.isEmpty else { return }
        isLoadingMyQuestions = true
        
        // ★★★ 修正: 認証トークンを取得 ★★★
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("自分の質問リスト取得: 認証トークン取得失敗")
            self.myQuestions = []
            isLoadingMyQuestions = false
            return
        }
        
        let url = usersApiEndpoint.appendingPathComponent(authorId).appendingPathComponent("questions")
        do {
            // ★★★ URLRequest を使用してトークンを送信 ★★★
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("自分の質問リスト取得時にサーバーエラー: \(response)")
                self.myQuestions = []
                isLoadingMyQuestions = false
                return
            }
            
            self.myQuestions = try JSONDecoder().decode([Question].self, from: data)
            print("✅ 自分の質問リストの取得に成功。件数: \(myQuestions.count)")
            
            // ★★★ デバッグ: 各質問の shareCode を確認 ★★★
            for (index, question) in self.myQuestions.enumerated() {
                print("📋 Question[\(index)]: title=\(question.title), shareCode=\(question.shareCode ?? "❌NIL")")
            }
            
        } catch {
            print("自分の質問リストの取得またはデコードに失敗: \(error)")
            self.myQuestions = []
        }
        isLoadingMyQuestions = false
    }
    // --- ★★★ 修正ここまで ★★★ ---
    
    func fetchUserStats(userId: String) async {
        guard !userId.isEmpty else { return }
        isLoadingUserStats = true
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("stats")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("成績取得時にサーバーエラー: \(response)")
                self.userStats = nil
                isLoadingUserStats = false
                return
            }
            self.userStats = try JSONDecoder().decode(UserStats.self, from: data)
            print("ユーザー成績の取得に成功。")
        } catch {
            print("ユーザー成績の取得またはデコードに失敗: \(error)")
            self.userStats = nil
        }
        isLoadingUserStats = false
    }
    func fetchQuestionAnalytics(questionId: String) async {
        guard !questionId.isEmpty else { return }
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("質問分析: 認証トークン取得失敗")
            analyticsError = "認証情報がありません。"
            isAnalyticsLoading = false
            return
        }
        isAnalyticsLoading = true
        analyticsError = nil
        analyticsResult = nil
        let url = questionsApiEndpoint.appendingPathComponent(questionId).appendingPathComponent("analytics")
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("質問分析データ取得時にサーバーエラー: \(response)")
                analyticsError = "データの取得に失敗しました。"
                isAnalyticsLoading = false
                return
            }
            self.analyticsResult = try JSONDecoder().decode(QuestionAnalyticsResult.self, from: data)
            print("質問分析データの取得に成功。")
        } catch {
            print("質問分析データの取得またはデコードに失敗: \(error)")
            analyticsError = "データの形式が正しくありません。"
        }
        isAnalyticsLoading = false
    }
}
