import Foundation
import Combine
// API呼び出し自体はURLSessionを使うため、AWSClientRuntime は不要です

// (UserStats, QuestionAnalyticsResult, UserProfile, BookmarkResponse 構造体は変更なし)
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
struct UserProfile: Codable {
    let nickname: String?
    let notifyOnCorrectAnswer: Bool? // 通知設定
}
struct BookmarkResponse: Decodable {
    let bookmarks: [String] // もしキー名が違うならここを修正
}

// ★★★ 追加: ブロックリスト取得APIのレスポンス用構造体 ★★★
struct BlocklistResponse: Decodable {
    let blockedUserIds: [String]
}


@MainActor
class ProfileViewModel: ObservableObject {

    // (myQuestions ... deletionError までのプロパティは変更なし)
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
    @Published var userNicknames: [String: String] = [:]
    @Published var bookmarkedQuestionIds: Set<String> = []
    @Published var isLoadingBookmarks = false
    @Published var isDeletingQuestion = false
    @Published var deletionError: String?
    
    // (notifyOnCorrectAnswer, isLoadingSettings は変更なし)
    @Published var notifyOnCorrectAnswer: Bool = false
    @Published var isLoadingSettings: Bool = false

    // --- ★★★ ここからブロック関連のプロパティを追加 ★★★ ---
    @Published var blockedUserIds: Set<String> = []
    @Published var isLoadingBlocklist = false
    // --- ★★★ ここまで追加 ★★★ ---


    // (apiEndpoint の定義は変更なし)
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!
    private let questionsApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    
    // AuthViewModelを保持 (変更なし)
    private let authViewModel: AuthViewModel

    // initでAuthViewModelを受け取る (★修正★)
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        Task {
            if authViewModel.isSignedIn {
                // ★★★ ブックマークとブロックリスト取得を追加 ★★★
                await fetchBookmarks()
                await fetchBlocklist() // ★追加
            }
        }
    }

    // (deleteQuestion, fetchBookmarks, addBookmark, removeBookmark, isBookmarked 関数は変更なし)
    // ... (省略) ...
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

    // (handleSignIn, handleSignOut 関数を ★修正★)
    /// ログイン時に各種データを取得する
    func handleSignIn() {
        Task {
            await fetchBookmarks()
            await fetchBlocklist() // ★追加
        }
    }
    /// ログアウト時にローカルデータをクリアする
    func handleSignOut() {
        bookmarkedQuestionIds = []
        blockedUserIds = [] // ★追加
        userNicknames = [:] // ★ニックネームキャッシュもクリア
        myQuestions = [] // ★追加
        userStats = nil // ★追加
        print("ローカルのブックマーク、ブロックリスト、キャッシュ等をクリアしました。")
    }


    // (registerDeviceToken, fetchNickname, fetchMyProfile, updateNickname 関数は変更なし)
    // ... (省略) ...
    func registerDeviceToken(deviceTokenString: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else {
            print("デバイストークン登録: 未ログインのためスキップ")
            return
        }
        
        print("デバイストークンをサーバーに登録開始...")

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

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("デバイストークン登録APIエラー: \(response)")
                return
            }
            
            print("デバイストークン登録に成功しました。")

        } catch {
            print("デバイストークン登録APIリクエストエラー: \(error)")
        }
    }
    
    func fetchNickname(userId: String) async -> String {
        if let cachedNickname = userNicknames[userId] {
            print("ニックネーム(ID: \(userId))をキャッシュから取得: \(cachedNickname)")
            return cachedNickname.isEmpty ? "（未設定）" : cachedNickname
        }
        
        guard !userId.isEmpty else { return "不明" }

        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ニックネーム取得: 認証トークン取得失敗")
            return "認証エラー"
        }
        
        let url = usersApiEndpoint.appendingPathComponent(userId)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ニックネーム取得時にサーバーエラー(ID: \(userId)): \(response)")
                // ★ 404 Not Found など、取得失敗時はキャッシュに何も入れずにエラー文字列を返す
                // (DMListRowView側はキャッシュがnilのままなので「削除されたユーザー」と表示する)
                return "取得失敗"
            }
            
            // ★★★ ここから修正 ★★★
            // サーバーが200 OKでも、中身がnullや空 {} かもしれない
            // UserProfile (notifyOnCorrectAnswer を含む) をデコード
            guard let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
                // デコードに失敗（データが空 {} または UserProfile 構造体と一致しない）
                // ＝ ユーザーは存在するがプロファイルがない（削除された）とみなす
                print("ニックネーム取得: 200 OK だがプロファイル内容がデコード不可 (削除ユーザー？) ID: \(userId)")
                return "取得失敗" // キャッシュ(nil)のままにする
            }
            
            let fetchedNickname = profile.nickname ?? "" // ニックネームが null なら ""
            
            // 3. 取得した結果をキャッシュに保存 (ユーザーは存在する)
            userNicknames[userId] = fetchedNickname
            print("ニックネーム(ID: \(userId))をAPIから取得: \(fetchedNickname)")
            
            return fetchedNickname.isEmpty ? "（未設定）" : fetchedNickname // UI表示用に調整
            // ★★★ ここまで修正 ★★★

        } catch {
            print("ニックネーム取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
             // ★ catch時もキャッシュに何も入れない
            return "エラー"
        }
    }
    
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
            
            userNicknames[userId] = profile.nickname ?? ""

        } catch {
            print("プロファイル取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }

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
    
    // (fetchNotificationSettings, updateNotificationSetting 関数は変更なし)
    // ... (省略) ...
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

        } catch {
            print("通知設定取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }

    func updateNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }

        isLoadingSettings = true
        print("通知設定を更新: \(isOn)")

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
            
            let requestBody = ["notifyOnCorrectAnswer": isOn]
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("通知設定更新APIエラー: \(response)")
                self.notifyOnCorrectAnswer = !isOn
                isLoadingSettings = false
                return
            }
            
            print("通知設定の更新に成功しました。")
            isLoadingSettings = false

        } catch {
            print("通知設定更新APIリクエストエラー: \(error)")
            self.notifyOnCorrectAnswer = !isOn
            isLoadingSettings = false
        }
    }
    
    // (deleteAccount 関数は変更なし)
    // ... (省略) ...
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

    // --- ★★★ ここから通報・ブロック機能の関数を追加 ★★★ ---

    /// コンテンツを通報する
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
    
    /// 自分がブロックしているユーザーのIDリストを取得する
    func fetchBlocklist() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBlocklist else { return }

        isLoadingBlocklist = true
        print("ブロックリストの取得開始...")

        // GET /users/me/blocklist
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

    /// ユーザーをブロックする
    func addBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        
        let (wasInserted, _) = blockedUserIds.insert(blockedUserId)
        guard wasInserted else {
             print("ブロック追加: 既にローカルに存在 \(blockedUserId)")
             return true
        }
        print("ブロック追加 (ローカル): \(blockedUserId)")

        // POST /users/me/block
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

    /// ユーザーのブロックを解除する
    func removeBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }

        guard blockedUserIds.contains(blockedUserId) else {
             print("ブロック解除: ローカルに存在しない \(blockedUserId)")
             return true
        }
        blockedUserIds.remove(blockedUserId)
        print("ブロック解除 (ローカル): \(blockedUserId)")

        // DELETE /users/me/block/{blockedUserId}
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

    /// 指定したユーザーIDがブロックされているか確認する
    func isBlocked(userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    // --- ★★★ ここまで追加 ★★★ ---
    
    
    // (fetchMyQuestions, fetchUserStats, fetchQuestionAnalytics 関数は変更なし)
    // ... (省略) ...
    func fetchMyQuestions(authorId: String) async {
        guard !authorId.isEmpty else { return }
        isLoadingMyQuestions = true
        let url = usersApiEndpoint.appendingPathComponent(authorId).appendingPathComponent("questions")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("自分の質問リスト取得時にサーバーエラー: \(response)")
                self.myQuestions = []
                isLoadingMyQuestions = false
                return
            }
            self.myQuestions = try JSONDecoder().decode([Question].self, from: data)
            print("自分の質問リストの取得に成功。件数: \(myQuestions.count)")
        } catch {
            print("自分の質問リストの取得またはデコードに失敗: \(error)")
            self.myQuestions = []
        }
        isLoadingMyQuestions = false
    }

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
