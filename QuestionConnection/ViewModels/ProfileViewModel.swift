import Foundation
import Combine

// (UserStats, QuestionAnalyticsResult, UserProfile 構造体は変更なし)
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
    
    // --- ★★★ ここが修正点 ★★★ ---
    // 「@Published」を戻します。
    // これにより、キャッシュが更新されたら DMListRowView が自動的に再描画されます。
    @Published var userNicknames: [String: String] = [:]
    // --- ★★★ ここまで ★★★ ---

    // (apiEndpoint の定義は変更なし)
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!
    private let questionsApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!

    
    // [共通関数] 指定したuserIdのニックネームを取得する (キャッシュ対応)
    func fetchNickname(userId: String, idToken: String) async -> String {
        // 1. 既にキャッシュにあればそれを返す
        // ★ .isEmpty のチェックを削除（一度 "未設定"="" で取得した後もキャッシュとして有効にするため）
        if let cachedNickname = userNicknames[userId] {
            print("ニックネーム(ID: \(userId))をキャッシュから取得: \(cachedNickname)")
            // ★ キャッシュから返す値もUI表示用に調整
            return cachedNickname.isEmpty ? "（未設定）" : cachedNickname
        }
        
        // 2. キャッシュになければAPIを呼び出す
        guard !userId.isEmpty else { return "不明" }

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
            
            // 3. 取得した結果をキャッシュに保存（ここで @Published がUIに通知）
            userNicknames[userId] = fetchedNickname
            print("ニックネーム(ID: \(userId))をAPIから取得: \(fetchedNickname)")
            
            return fetchedNickname.isEmpty ? "（未設定）" : fetchedNickname // UI表示用に調整

        } catch {
            print("ニックネーム取得APIへのリクエスト中にエラー(ID: \(userId)): \(error)")
            return "エラー"
        }
    }
    
    // [ProfileView専用] 自分のニックネームを読み込む
    func fetchMyProfile(userId: String, idToken: String) async {
        guard !userId.isEmpty else { return }
        
        _ = await fetchNickname(userId: userId, idToken: idToken)
        
        // TextField にはAPIからの生のデータ（空文字）をセットする
        self.nickname = userNicknames[userId] ?? ""
    }

    // ニックネームを更新する関数
    func updateNickname(userId: String, idToken: String) async {
        guard !userId.isEmpty else { return }
        
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
            
            // ★ 更新成功したらキャッシュも更新（ここで @Published がUIに通知）
            userNicknames[userId] = nicknameToSave

        } catch {
            print("ニックネーム更新APIへのリクエスト中にエラー: \(error)")
            nicknameAlertMessage = "エラーが発生しました: \(error.localizedDescription)"
            showNicknameAlert = true
        }
        isNicknameLoading = false
    }
    
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

    func fetchQuestionAnalytics(questionId: String, idToken: String) async {
        guard !questionId.isEmpty else { return }
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
