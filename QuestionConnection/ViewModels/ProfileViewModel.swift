import Foundation
import Combine
// API呼び出し自体はURLSessionを使うため、AWSClientRuntime は不要です

// (UserStats, QuestionAnalyticsResult 構造体は変更なし)
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

// ★★★ 修正: UserProfile に通知設定 (notifyOnCorrectAnswer) を追加 ★★★
// ※バックエンドの getUserProfileFunction もこの値を返すように修正が必要です
struct UserProfile: Codable {
    let nickname: String?
    let notifyOnCorrectAnswer: Bool? // 通知設定
}

// ★★★ 追加: ブックマーク取得APIのレスポンス用構造体 ★★★
// APIが {"bookmarks": ["id1", "id2"]} という形式のJSONを返すことを想定
struct BookmarkResponse: Decodable {
    let bookmarks: [String] // もしキー名が違うならここを修正
}


@MainActor
class ProfileViewModel: ObservableObject {

    // (myQuestions, userStats, ... analyticsError までのプロパティは変更なし)
    @Published var myQuestions: [Question] = []
    @Published var userStats: UserStats?
    @Published var isLoadingMyQuestions = false
    @Published var isLoadingUserStats = false
    @Published var analyticsResult: QuestionAnalyticsResult?
    @Published var isAnalyticsLoading = false
    @Published var analyticsError: String?
    
    // (nickname, isNicknameLoading, ... showNicknameAlert までのプロパティは変更なし)
    @Published var nickname: String = ""
    @Published var isNicknameLoading = false
    @Published var nicknameAlertMessage: String?
    @Published var showNicknameAlert = false
    
    // キャッシュ
    @Published var userNicknames: [String: String] = [:]
    
    // ★★★ ブックマーク関連のプロパティ (変更なし) ★★★
    @Published var bookmarkedQuestionIds: Set<String> = []
    @Published var isLoadingBookmarks = false // ブックマーク取得中の状態

    // ★★★ 質問削除用の状態 (変更なし) ★★★
    @Published var isDeletingQuestion = false
    @Published var deletionError: String?

    // --- ★★★ ここから通知設定用のプロパティを追加 ★★★ ---
    @Published var notifyOnCorrectAnswer: Bool = false // SettingsViewのトグルがバインドする先
    @Published var isLoadingSettings: Bool = false // 設定読み込み/更新中のローディング表示用
    // --- ★★★ ここまで追加 ★★★ ---

    // (apiEndpoint の定義は変更なし)
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!
    private let questionsApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    
    // AuthViewModelを保持 (変更なし)
    private let authViewModel: AuthViewModel

    // initでAuthViewModelを受け取る (変更なし)
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        Task {
            // ★★★ 修正: ログイン状態を確認してから取得 ★★★
            if authViewModel.isSignedIn {
                await fetchBookmarks()
            }
        }
    }

    
    // (deleteQuestion 関数は変更なし)
    /// 質問を削除する (バックエンドAPI呼び出し)
    /// - Parameter questionId: 削除する質問のID
    /// - Returns: 削除に成功した場合は true, 失敗した場合は false
    func deleteQuestion(questionId: String) async -> Bool {
        guard authViewModel.isSignedIn, !isDeletingQuestion else { return false }

        isDeletingQuestion = true
        deletionError = nil
        print("質問削除開始: \(questionId)")

        // ★★★ 修正: 実際のAPI呼び出し (DELETE /questions/{questionId}) ★★★
        // questionsApiEndpoint を使用
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

            // 成功時は 204 No Content または 200 OK を想定
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                print("質問削除APIエラー: \(response)")
                // TODO: レスポンスボディから詳細なエラーメッセージを取得する
                deletionError = "質問の削除に失敗しました (サーバーエラー)。"
                isDeletingQuestion = false
                return false
            }

            print("質問削除API成功: \(questionId)")
            // ★★★ 追加: 成功したらローカルのリストからも削除 ★★★
            // id は Question 構造体のプロパティ名に合わせてください (questionId かもしれません)
            myQuestions.removeAll { $0.questionId == questionId } // $0.id or $0.questionId
            
            isDeletingQuestion = false
            return true

        } catch {
            print("質問削除APIリクエストエラー: \(error)")
            deletionError = "質問の削除中にエラーが発生しました: \(error.localizedDescription)"
            isDeletingQuestion = false
            return false
        }
    }

    // (fetchBookmarks, addBookmark, removeBookmark 関数は変更なし)
    /// ユーザーのブックマークIDリストを取得する (API実装)
    func fetchBookmarks() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBookmarks else { return }

        isLoadingBookmarks = true
        print("ブックマークリストの取得開始...")

        // GET /users/{userId}/bookmarks
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")

        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク取得: 認証トークン取得失敗")
                isLoadingBookmarks = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET" // GETメソッド
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ブックマーク取得APIエラー: \(response)")
                isLoadingBookmarks = false
                return
            }

            // ★★★ 修正: APIが返す形式に合わせてデコード (例: {"bookmarks": ["id1", "id2"]} の場合) ★★★
            let responseData = try JSONDecoder().decode(BookmarkResponse.self, from: data)
            self.bookmarkedQuestionIds = Set(responseData.bookmarks)
            print("ブックマークリスト取得完了。件数: \(bookmarkedQuestionIds.count)")

        } catch {
            print("ブックマーク取得APIリクエストエラー: \(error)")
        }

        isLoadingBookmarks = false
    }

    /// 質問をブックマークに追加する (API実装)
    func addBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }

        // ローカルの状態を先に更新
        let (wasInserted, _) = bookmarkedQuestionIds.insert(questionId)
        guard wasInserted else {
             print("ブックマーク追加: 既にローカルに存在 \(questionId)")
             return
        }
        print("ブックマーク追加 (ローカル): \(questionId)")

        // ★★★ 修正: 実際のAPI呼び出し ★★★
        // POST /users/{userId}/bookmarks
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")

        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク追加: 認証トークン取得失敗")
                bookmarkedQuestionIds.remove(questionId) // ローカルの変更を戻す
                // TODO: ユーザーにエラーを通知
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
                bookmarkedQuestionIds.remove(questionId) // ローカルの変更を戻す
                // TODO: ユーザーにエラーを通知
                return
            }
            print("ブックマーク追加API成功: \(questionId)")

        } catch {
            print("ブックマーク追加APIリクエストエラー: \(error)")
            bookmarkedQuestionIds.remove(questionId) // ローカルの変更を戻す
            // TODO: ユーザーにエラーを通知
        }
    }

    /// 質問をブックマークから削除する (API実装)
    func removeBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }

        // ローカルの状態を先に更新
        guard bookmarkedQuestionIds.contains(questionId) else {
             print("ブックマーク削除: ローカルに存在しない \(questionId)")
             return
        }
        bookmarkedQuestionIds.remove(questionId)
        print("ブックマーク削除 (ローカル): \(questionId)")

        // ★★★ 修正: 実際のAPI呼び出し ★★★
        // DELETE /users/{userId}/bookmarks/{questionId}
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks").appendingPathComponent(questionId)

        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                print("ブックマーク削除: 認証トークン取得失敗")
                bookmarkedQuestionIds.insert(questionId) // ローカルの変更を戻す
                // TODO: ユーザーにエラーを通知
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                print("ブックマーク削除APIエラー: \(response)")
                bookmarkedQuestionIds.insert(questionId) // ローカルの変更を戻す
                // TODO: ユーザーにエラーを通知
                return
            }
            print("ブックマーク削除API成功: \(questionId)")

        } catch {
            print("ブックマーク削除APIリクエストエラー: \(error)")
            bookmarkedQuestionIds.insert(questionId) // ローカルの変更を戻す
            // TODO: ユーザーにエラーを通知
        }
    }

    // (isBookmarked 関数は変更なし)
    /// 指定した質問IDがブックマークされているか確認する (変更なし)
    func isBookmarked(questionId: String) -> Bool {
        return bookmarkedQuestionIds.contains(questionId)
    }

    // (handleSignIn, handleSignOut 関数は変更なし)
    /// ログイン時にブックマークを取得する
    func handleSignIn() {
        Task {
            await fetchBookmarks()
        }
    }
    /// ログアウト時にブックマークをクリアする
    func handleSignOut() {
        bookmarkedQuestionIds = []
        print("ローカルのブックマークをクリアしました。") // ログアウト確認用
    }


    // --- ★★★ ここからデバイストークン登録用の関数を追加 ★★★ ---
    
    /// 取得したデバイストークンをサーバーに登録する
    /// - Parameter deviceTokenString: iOSから取得した生のデバイストークン文字列
    func registerDeviceToken(deviceTokenString: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else {
            print("デバイストークン登録: 未ログインのためスキップ")
            return
        }
        
        // TODO: 現在保存されているトークンと変更がないかチェックし、同じならAPI呼び出しをスキップするロジック (任意)
        
        print("デバイストークンをサーバーに登録開始...")

        // POST /users/{userId}/deviceToken
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
            
            // Lambda (registerDeviceTokenFunction) が期待するボディ
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
    // --- ★★★ ここまで追加 ★★★ ---


    // (fetchNickname 関数は変更なし)
    // [共通関数] 指定したuserIdのニックネームを取得する (キャッシュ対応)
    func fetchNickname(userId: String) async -> String {
        // 1. 既にキャッシュにあればそれを返す
        if let cachedNickname = userNicknames[userId] {
            print("ニックネーム(ID: \(userId))をキャッシュから取得: \(cachedNickname)")
            return cachedNickname.isEmpty ? "（未設定）" : cachedNickname
        }
        
        guard !userId.isEmpty else { return "不明" }

        // ★★★ 関数内で getValidIdToken を呼び出す ★★★
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ニックネーム取得: 認証トークン取得失敗")
            return "認証エラー"
        }
        
        // 2. キャッシュになければAPIを呼び出す
        let url = usersApiEndpoint.appendingPathComponent(userId)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("ニックネーム取得時にサーバーエラー(ID: \(userId)): \(response)")
                return "取得失敗"
            }
            
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            let fetchedNickname = profile.nickname ?? "" // 未設定なら空文字
            
            // 3. 取得した結果をキャッシュに保存
            userNicknames[userId] = fetchedNickname
            print("ニックネーム(ID: \(userId))をAPIから取得: \(fetchedNickname)")
            
            return fetchedNickname.isEmpty ? "（未設定）" : fetchedNickname // UI表示用に調整

        } catch {
            print("ニックネーム取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
            return "エラー"
        }
    }
    
    // [ProfileView専用] 自分のプロファイル（ニックネームと設定）を読み込む
    // ★★★ 修正: fetchNicknameを呼び出す代わりに、ここで直接APIを叩き、通知設定も取得する ★★★
    func fetchMyProfile(userId: String) async {
        guard !userId.isEmpty else { return }
        
        isLoadingSettings = true // ニックネームと設定を両方ロード
        
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("プロファイル取得: 認証トークン取得失敗")
            isLoadingSettings = false
            return
        }

        let url = usersApiEndpoint.appendingPathComponent(userId) // GET /users/{userId}
        
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
            
            // UserProfile (notifyOnCorrectAnswer を含む) をデコード
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            
            // ニックネームを更新
            self.nickname = profile.nickname ?? ""
            // ★★★ 通知設定を更新 (デフォルトはfalse) ★★★
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false
            
            // キャッシュも更新
            userNicknames[userId] = profile.nickname ?? ""

        } catch {
            print("プロファイル取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }

    // (updateNickname 関数は変更なし)
    // ニックネームを更新する関数
    func updateNickname(userId: String) async {
        guard !userId.isEmpty else { return }
        
        // ★★★ 関数内で getValidIdToken を呼び出す ★★★
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
            // 更新成功したらキャッシュも更新
            userNicknames[userId] = nicknameToSave

        } catch {
            print("ニックネーム更新APIへのリクエスト中にエラー: \(error)")
            nicknameAlertMessage = "エラーが発生しました: \(error.localizedDescription)"
            showNicknameAlert = true
        }
        isNicknameLoading = false
    }
    
    // --- ★★★ ここから通知設定用の関数を追加 ★★★ ---

    /// [SettingsView専用] 自分の現在の通知設定を読み込む (fetchMyProfileが既に読み込んでいる場合は不要だが、SettingsView用に分離)
    func fetchNotificationSettings() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return } // 既に読み込み中ならスキップ

        isLoadingSettings = true
        
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("通知設定取得: 認証トークン取得失敗")
            isLoadingSettings = false
            return
        }

        let url = usersApiEndpoint.appendingPathComponent(userId) // GET /users/{userId}
        
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
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false // デフォルトはOFF

        } catch {
            print("通知設定取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
        }
        isLoadingSettings = false
    }

    /// 通知設定を更新する (PUT /users/{userId}/settings)
    func updateNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return } // 二重送信防止

        isLoadingSettings = true
        print("通知設定を更新: \(isOn)")

        // PUT /users/{userId}/settings
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
                // ★★★ エラー時はUI（トグルスイッチ）を元の状態に戻す ★★★
                self.notifyOnCorrectAnswer = !isOn
                isLoadingSettings = false
                return
            }
            
            print("通知設定の更新に成功しました。")
            // 成功時はローカルの状態 (self.notifyOnCorrectAnswer) は既にUIと一致しているので変更不要
            isLoadingSettings = false

        } catch {
            print("通知設定更新APIリクエストエラー: \(error)")
            // ★★★ エラー時はUI（トグルスイッチ）を元の状態に戻す ★★★
            self.notifyOnCorrectAnswer = !isOn
            isLoadingSettings = false
        }
    }
    // --- ★★★ ここまで追加 ★★★ ---

    // --- ★★★ ここからアカウント削除用の関数を追加 ★★★ ---

    /// アカウントを削除する
    /// - Returns: 成功した場合は true, 失敗した場合は false
    func deleteAccount() async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else {
            print("ProfileViewModel: 未ログインのためアカウント削除を実行できません。")
            return false
        }
        
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ProfileViewModel: 認証トークン取得失敗")
            return false
        }

        // ★★★ API Gatewayで作成したURL ★★★
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
    // --- ★★★ ここまで追加 ★★★ ---
    
    // --- ★★★ ここから通報用の関数を追加 ★★★ ---
    
    /// コンテンツを通報する
    /// - Parameters:
    ///   - targetId: 通報対象のID (例: questionId)
    ///   - targetType: 通報対象の種類 (例: "question")
    ///   - reason: 通報理由 (例: "inappropriate")
    ///   - detail: 詳細
    /// - Returns: 成功した場合は true
    func reportContent(targetId: String, targetType: String, reason: String, detail: String) async -> Bool {
        guard authViewModel.isSignedIn else {
            print("ProfileViewModel: 未ログインのため通報できません。")
            return false
        }
        
        guard let idToken = await authViewModel.getValidIdToken() else {
            print("ProfileViewModel: 認証トークン取得失敗 (通報)")
            return false
        }

        // ★★★ API Gatewayで作成したURL ★★★
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
    // --- ★★★ ここまで追加 ★★★ ---
    
    
    // (fetchMyQuestions, fetchUserStats, fetchQuestionAnalytics 関数は変更なし)
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
        
        // ★★★ 関数内で getValidIdToken を呼び出す ★★★
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
