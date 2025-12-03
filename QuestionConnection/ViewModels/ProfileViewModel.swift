import Foundation
import Combine
import UIKit

// MARK: - Data Models

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
    let notifyOnCorrectAnswer: Bool?
    let notifyOnDM: Bool?
    let notifyOnGradeResult: Bool? // 採点結果の通知設定
    let profileImageUrl: String?
}

struct BookmarkResponse: Decodable {
    let bookmarks: [String]
}

struct BlocklistResponse: Decodable {
    let blockedUserIds: [String]
}

// --- 採点機能用モデル ---
struct AnswerLogItem: Codable, Identifiable {
    let logId: String
    let userId: String
    var status: String // pending_review, approved, rejected, completed
    let score: Int
    let total: Int
    let updatedAt: String
    let details: [AnswerDetail]
    
    // ★ 追加: 質問情報（Lambdaで結合される想定）
    let questionTitle: String?
    let questionId: String // 必須
    let authorId: String?  // DM作成などに必要
    
    var id: String { logId }
}

struct AnswerDetail: Codable, Identifiable {
    let itemId: String
    let type: String // choice, fillIn, essay
    let userAnswer: UserAnswerValue? // 柔軟に対応
    let isCorrect: Bool
    let status: String
    
    var id: String { itemId }
}

// 回答値はStringの場合とDictionaryの場合があるので柔軟に受ける
enum UserAnswerValue: Codable {
    case string(String)
    case dictionary([String: String])
    case none
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode([String: String].self) {
            self = .dictionary(x)
            return
        }
        self = .none
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .dictionary(let x): try container.encode(x)
        case .none: try container.encodeNil()
        }
    }
    
    var displayString: String {
        switch self {
        case .string(let s): return s
        case .dictionary(let d): return d.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        case .none: return "(回答なし)"
        }
    }
}

// MARK: - ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // 質問管理
    @Published var myQuestions: [Question] = []
    @Published var isLoadingMyQuestions = false
    @Published var isDeletingQuestion = false
    @Published var deletionError: String?
    
    // ユーザー統計・分析
    @Published var userStats: UserStats?
    @Published var isLoadingUserStats = false
    @Published var analyticsResult: QuestionAnalyticsResult?
    @Published var isAnalyticsLoading = false
    @Published var analyticsError: String?
    
    // プロフィール情報
    @Published var nickname: String = ""
    @Published var isNicknameLoading = false
    @Published var nicknameAlertMessage: String?
    @Published var showNicknameAlert = false
    
    // ブロック・ブックマーク
    @Published var blockedUserIds: Set<String> = []
    @Published var isLoadingBlocklist = false
    @Published var bookmarkedQuestionIds: Set<String> = []
    @Published var isLoadingBookmarks = false
    
    // 通知設定
    @Published var notifyOnCorrectAnswer: Bool = false
    @Published var notifyOnDM: Bool = false
    @Published var notifyOnGradeResult: Bool = true // デフォルトはON
    @Published var isLoadingSettings: Bool = false
    
    // キャッシュ
    @Published var userNicknames: [String: String] = [:]
    @Published var userProfileImages: [String: String] = [:]
    
    // プロフィール画像アップロード関連
    @Published var profileImageAlertMessage: String?
    @Published var showProfileImageAlert = false
    @Published var isUploadingProfileImage = false
    @Published var remainingProfileImageChanges: Int = 2
    @Published var profileImageChangedCount: Int = 0
    
    // --- 採点・回答結果用 ---
    @Published var answerLogs: [AnswerLogItem] = [] // 自分が作成した質問への回答（採点用）
    @Published var myGradedAnswers: [AnswerLogItem] = [] // ★ 追加: 自分が回答した履歴（結果確認用）
    @Published var isLoadingAnswers = false
    @Published var isJudging = false
    
    // ★ 追加: 模範解答表示用
    @Published var selectedQuestionForModelAnswer: Question?
    @Published var isFetchingQuestionDetail = false
    
    // MARK: - Private Properties
    
    private var inFlightNicknameTasks: [String: Task<String, Never>] = [:]
    private var failedAt: [String: Date] = [:]
    private let retryCooldown: TimeInterval = 60
    
    // API Endpoints
    let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!
    let questionsApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    
    private let authViewModel: AuthViewModel
    
    // MARK: - Init
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        Task {
            if authViewModel.isSignedIn {
                await fetchBookmarks()
                await fetchBlocklist()
                await checkAndRegisterPendingDeviceToken()
            }
        }
    }
    
    // MARK: - 採点機能関連メソッド (New & Updated)
    
    // 自分が作成した質問への回答一覧を取得（採点画面用）
    func fetchAnswerLogs(questionId: String) async {
        guard !questionId.isEmpty else { return }
        isLoadingAnswers = true
        let url = questionsApiEndpoint.appendingPathComponent(questionId).appendingPathComponent("answers")
        
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return }
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("回答一覧取得エラー: \(response)")
                isLoadingAnswers = false
                return
            }
            
            let logs = try JSONDecoder().decode([AnswerLogItem].self, from: data)
            self.answerLogs = logs
        } catch {
            print("回答一覧取得失敗: \(error)")
        }
        isLoadingAnswers = false
    }
    
    // ★ 新機能: 自分の回答履歴を取得（結果確認画面用）
    func fetchMyGradedAnswers() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        // isLoadingAnswers = true // 必要に応じてフラグ操作
        
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("answers")
        
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return }
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("自分の回答履歴取得エラー: \(response)")
                return
            }
            
            let logs = try JSONDecoder().decode([AnswerLogItem].self, from: data)
            self.myGradedAnswers = logs
            print("自分の回答履歴取得成功: \(logs.count)件")
        } catch {
            print("自分の回答履歴取得失敗: \(error)")
        }
    }
    
    // ★ 新機能: 模範解答表示のために質問詳細を取得
    func fetchQuestionDetailForModelAnswer(questionId: String) async {
        guard !questionId.isEmpty else { return }
        isFetchingQuestionDetail = true
        selectedQuestionForModelAnswer = nil
        
        let url = questionsApiEndpoint.appendingPathComponent(questionId)
        do {
            // 公開情報の取得なので認証不要の場合もあるが、念のため
            var request = URLRequest(url: url)
            if let idToken = await authViewModel.getValidIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("質問詳細取得エラー: \(response)")
                isFetchingQuestionDetail = false
                return
            }
            
            let question = try JSONDecoder().decode(Question.self, from: data)
            self.selectedQuestionForModelAnswer = question
        } catch {
            print("質問詳細取得エラー: \(error)")
        }
        isFetchingQuestionDetail = false
    }
    
    // 採点実行 (正解/不正解)
    func judgeAnswer(logId: String, isApproved: Bool) async -> Bool {
        guard !logId.isEmpty, let authorId = authViewModel.userSub else { return false }
        isJudging = true
        
        let urlString = "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/answers/judge"
        guard let url = URL(string: urlString) else { return false }
        
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return false }
            
            let body: [String: Any] = [
                "authorId": authorId,
                "logId": logId,
                "isApproved": isApproved
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                isJudging = false
                return false
            }
            
            // ローカルデータを即時更新
            if let index = answerLogs.firstIndex(where: { $0.logId == logId }) {
                answerLogs[index].status = isApproved ? "approved" : "rejected"
            }
            isJudging = false
            return true
            
        } catch {
            print("採点エラー: \(error)")
            isJudging = false
            return false
        }
    }
    
    // 採点通知設定の更新
    func updateGradeNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        self.notifyOnGradeResult = isOn
        
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("settings")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let body = ["notifyOnGradeResult": isOn]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("設定更新エラー: \(http.statusCode)")
                self.notifyOnGradeResult = !isOn // 戻す
            }
        } catch {
            print("通信エラー: \(error)")
            self.notifyOnGradeResult = !isOn
        }
    }
    
    // MARK: - Profile & Settings
    
    func fetchMyProfile(userId: String) async {
        guard !userId.isEmpty else { return }
        isLoadingSettings = true
        guard let idToken = await authViewModel.getValidIdToken() else {
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
                isLoadingSettings = false
                return
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.nickname = profile.nickname ?? ""
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false
            self.notifyOnDM = profile.notifyOnDM ?? false
            self.notifyOnGradeResult = profile.notifyOnGradeResult ?? true
            
            // キャッシュ更新
            userNicknames[userId] = profile.nickname ?? ""
            if let img = profile.profileImageUrl {
                userProfileImages[userId] = img
            }
        } catch {
            print("プロファイル取得エラー: \(error)")
        }
        isLoadingSettings = false
    }
    
    func updateNickname(userId: String) async {
        guard !userId.isEmpty else { return }
        guard let idToken = await authViewModel.getValidIdToken() else {
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
                nicknameAlertMessage = "ニックネームの保存に失敗しました。"
                showNicknameAlert = true
                isNicknameLoading = false
                return
            }
            nicknameAlertMessage = "ニックネームを保存しました。"
            showNicknameAlert = true
            userNicknames[userId] = nicknameToSave
        } catch {
            nicknameAlertMessage = "エラーが発生しました: \(error.localizedDescription)"
            showNicknameAlert = true
        }
        isNicknameLoading = false
    }
    
    func fetchNotificationSettings() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                isLoadingSettings = false
                return
            }
            
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            self.notifyOnCorrectAnswer = profile.notifyOnCorrectAnswer ?? false
            self.notifyOnDM = profile.notifyOnDM ?? false
            self.notifyOnGradeResult = profile.notifyOnGradeResult ?? true
            
        } catch {
            print("設定取得エラー: \(error)")
        }
        isLoadingSettings = false
    }
    
    func updateNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("settings")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
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
                self.notifyOnCorrectAnswer = !isOn
                isLoadingSettings = false
                return
            }
            isLoadingSettings = false
        } catch {
            self.notifyOnCorrectAnswer = !isOn
            isLoadingSettings = false
        }
    }
    
    func updateDMNotificationSetting(isOn: Bool) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard !isLoadingSettings else { return }
        isLoadingSettings = true
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("settings")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                isLoadingSettings = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let requestBody = ["notifyOnDM": isOn]
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.notifyOnDM = !isOn
                isLoadingSettings = false
                return
            }
            isLoadingSettings = false
        } catch {
            self.notifyOnDM = !isOn
            isLoadingSettings = false
        }
    }
    
    // MARK: - Profile Image & Cache
    
    func uploadProfileImage(userId: String, image: UIImage) async {
        guard let idToken = await authViewModel.getValidIdToken() else {
            profileImageAlertMessage = "認証に失敗しました。"
            showProfileImageAlert = true
            return
        }
        
        isUploadingProfileImage = true
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            profileImageAlertMessage = "画像の処理に失敗しました。"
            showProfileImageAlert = true
            isUploadingProfileImage = false
            return
        }
        
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("profileImage")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                await MainActor.run {
                    switch httpResponse.statusCode {
                    case 200...299:
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let imageUrl = json["profileImageUrl"] as? String {
                                self.userProfileImages[userId] = imageUrl
                            }
                            if let changeCount = json["changeCount"] as? Int,
                               let maxChanges = json["maxChanges"] as? Int {
                                self.profileImageChangedCount = changeCount
                                self.remainingProfileImageChanges = maxChanges - changeCount
                            }
                            self.profileImageAlertMessage = "プロフィール画像をアップロードしました✓"
                            self.showProfileImageAlert = true
                        }
                    case 403:
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let changeCount = json["changeCount"] as? Int,
                               let maxChanges = json["maxChanges"] as? Int {
                                self.profileImageChangedCount = changeCount
                                self.remainingProfileImageChanges = maxChanges - changeCount
                            }
                            if let nextDate = json["nextAvailableDate"] as? String {
                                self.profileImageAlertMessage = "今月のプロフィール変更の上限に達しました\n(\(nextDate)以降に再度お試しください)"
                            } else {
                                self.profileImageAlertMessage = "今月のプロフィール変更の上限に達しました"
                            }
                        } else {
                            self.profileImageAlertMessage = "今月のプロフィール変更の上限に達しました"
                        }
                        self.showProfileImageAlert = true
                    case 413:
                        self.profileImageAlertMessage = "画像ファイルが大きすぎます（最大10MB）"
                        self.showProfileImageAlert = true
                    default:
                        self.profileImageAlertMessage = "画像のアップロードに失敗しました（エラー: \(httpResponse.statusCode)）"
                        self.showProfileImageAlert = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.profileImageAlertMessage = "エラーが発生しました: \(error.localizedDescription)"
                self.showProfileImageAlert = true
            }
        }
        isUploadingProfileImage = false
    }
    
    func fetchNickname(userId: String) async -> String {
        if let cached = userNicknames[userId] {
            return cached.isEmpty ? "（未設定）" : cached
        }
        if let lastFailed = failedAt[userId], Date().timeIntervalSince(lastFailed) < retryCooldown {
            return "(削除されたユーザー)"
        }
        if let task = inFlightNicknameTasks[userId] {
            let name = await task.value
            return name.isEmpty ? "(削除されたユーザー)" : name
        }
        guard !userId.isEmpty else { return "不明" }
        let task = Task<String, Never> { [weak self] in
            guard let self else { return "" }
            let name = await self.requestNicknameFromAPI(userId: userId)
            return name ?? ""
        }
        inFlightNicknameTasks[userId] = task
        let name = await task.value
        self.userNicknames[userId] = name
        inFlightNicknameTasks.removeValue(forKey: userId)
        if name.isEmpty {
            failedAt[userId] = Date()
            return name.isEmpty ? "(削除されたユーザー)" : name
        } else {
            failedAt.removeValue(forKey: userId)
            return name
        }
    }
    
    func fetchNicknameAndImage(userId: String) async -> (nickname: String, imageUrl: String?) {
        if let cached = userNicknames[userId] {
            return (cached, userProfileImages[userId])
        }
        let endpoint = "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users/\(userId)"
        guard let url = URL(string: endpoint) else {
            return ("不明", nil)
        }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            if let token = await authViewModel.getValidIdToken() {
                request.setValue(token, forHTTPHeaderField: "Authorization")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: data)
            let nickname = profile.nickname ?? "（未設定）"
            let imageUrl = profile.profileImageUrl
            await MainActor.run {
                self.userNicknames[userId] = nickname
                if let imageUrl = imageUrl {
                    self.userProfileImages[userId] = imageUrl
                }
            }
            return (nickname, imageUrl)
        } catch {
            await MainActor.run {
                self.userNicknames[userId] = "不明"
            }
            return ("不明", nil)
        }
    }
    
    private func requestNicknameFromAPI(userId: String) async -> String? {
        guard !userId.isEmpty else { return nil }
        guard let idToken = await authViewModel.getValidIdToken() else { return nil }
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else { return nil }
            return profile.nickname
        } catch { return nil }
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
    
    // MARK: - Bookmarks & Blocklist
    
    func fetchBookmarks() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBookmarks else { return }
        isLoadingBookmarks = true
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                isLoadingBookmarks = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                isLoadingBookmarks = false
                return
            }
            let responseData = try JSONDecoder().decode(BookmarkResponse.self, from: data)
            self.bookmarkedQuestionIds = Set(responseData.bookmarks)
        } catch {
            print("ブックマーク取得エラー: \(error)")
        }
        isLoadingBookmarks = false
    }
    
    func addBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        let (wasInserted, _) = bookmarkedQuestionIds.insert(questionId)
        guard wasInserted else { return }
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
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
                bookmarkedQuestionIds.remove(questionId)
                return
            }
        } catch {
            bookmarkedQuestionIds.remove(questionId)
        }
    }
    
    func removeBookmark(questionId: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        guard bookmarkedQuestionIds.contains(questionId) else { return }
        bookmarkedQuestionIds.remove(questionId)
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("bookmarks").appendingPathComponent(questionId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                bookmarkedQuestionIds.insert(questionId)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                bookmarkedQuestionIds.insert(questionId)
                return
            }
        } catch {
            bookmarkedQuestionIds.insert(questionId)
        }
    }
    
    func isBookmarked(questionId: String) -> Bool {
        return bookmarkedQuestionIds.contains(questionId)
    }
    
    func fetchBlocklist() async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn, !isLoadingBlocklist else { return }
        isLoadingBlocklist = true
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("blocklist")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                isLoadingBlocklist = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                isLoadingBlocklist = false
                return
            }
            let responseData = try JSONDecoder().decode(BlocklistResponse.self, from: data)
            self.blockedUserIds = Set(responseData.blockedUserIds)
        } catch {
            print("ブロックリスト取得エラー: \(error)")
        }
        isLoadingBlocklist = false
    }
    
    func addBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        let (wasInserted, _) = blockedUserIds.insert(blockedUserId)
        if !wasInserted { return true }
        
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("block")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
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
                blockedUserIds.remove(blockedUserId)
                return false
            }
            return true
        } catch {
            blockedUserIds.remove(blockedUserId)
            return false
        }
    }
    
    func removeBlock(blockedUserId: String) async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        if !blockedUserIds.contains(blockedUserId) { return true }
        blockedUserIds.remove(blockedUserId)
        
        let url = usersApiEndpoint.appendingPathComponent("me").appendingPathComponent("block").appendingPathComponent(blockedUserId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                blockedUserIds.insert(blockedUserId)
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                blockedUserIds.insert(blockedUserId)
                return false
            }
            return true
        } catch {
            blockedUserIds.insert(blockedUserId)
            return false
        }
    }
    
    func isBlocked(userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    
    // MARK: - Questions & Stats
    
    func fetchMyQuestions(authorId: String) async {
        guard !authorId.isEmpty else { return }
        isLoadingMyQuestions = true
        let url = usersApiEndpoint.appendingPathComponent(authorId).appendingPathComponent("questions")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.myQuestions = []
                isLoadingMyQuestions = false
                return
            }
            self.myQuestions = try JSONDecoder().decode([Question].self, from: data)
        } catch {
            self.myQuestions = []
        }
        isLoadingMyQuestions = false
    }
    
    func deleteQuestion(questionId: String) async -> Bool {
        guard authViewModel.isSignedIn, !isDeletingQuestion else { return false }
        isDeletingQuestion = true
        deletionError = nil
        let url = questionsApiEndpoint.appendingPathComponent(questionId)
        do {
            guard let idToken = await authViewModel.getValidIdToken() else {
                deletionError = "認証情報がありません。"
                isDeletingQuestion = false
                return false
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 204 || httpResponse.statusCode == 200) else {
                deletionError = "質問の削除に失敗しました。"
                isDeletingQuestion = false
                return false
            }
            myQuestions.removeAll { $0.questionId == questionId }
            isDeletingQuestion = false
            return true
        } catch {
            deletionError = "エラーが発生しました: \(error.localizedDescription)"
            isDeletingQuestion = false
            return false
        }
    }
    
    func fetchUserStats(userId: String) async {
        guard !userId.isEmpty else { return }
        isLoadingUserStats = true
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("stats")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.userStats = nil
                isLoadingUserStats = false
                return
            }
            self.userStats = try JSONDecoder().decode(UserStats.self, from: data)
        } catch {
            self.userStats = nil
        }
        isLoadingUserStats = false
    }
    
    func fetchQuestionAnalytics(questionId: String) async {
        guard !questionId.isEmpty else { return }
        guard let idToken = await authViewModel.getValidIdToken() else {
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
                analyticsError = "データの取得に失敗しました。"
                isAnalyticsLoading = false
                return
            }
            self.analyticsResult = try JSONDecoder().decode(QuestionAnalyticsResult.self, from: data)
        } catch {
            analyticsError = "データの形式が正しくありません。"
        }
        isAnalyticsLoading = false
    }
    
    // MARK: - Other Actions
    
    func deleteAccount() async -> Bool {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return false }
        guard let idToken = await authViewModel.getValidIdToken() else { return false }
        let url = usersApiEndpoint.appendingPathComponent(userId)
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) else { return false }
            return true
        } catch { return false }
    }
    
    func reportContent(targetId: String, targetType: String, reason: String, detail: String) async -> Bool {
        guard authViewModel.isSignedIn else { return false }
        guard let idToken = await authViewModel.getValidIdToken() else { return false }
        let url = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/reports")!
        let requestBody = [
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
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else { return false }
            return true
        } catch { return false }
    }
    
    // デバイストークン登録
    func registerDeviceToken(deviceTokenString: String) async {
        guard let userId = authViewModel.userSub, authViewModel.isSignedIn else { return }
        let url = usersApiEndpoint.appendingPathComponent(userId).appendingPathComponent("deviceToken")
        do {
            guard let idToken = await authViewModel.getValidIdToken() else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let requestBody = ["deviceToken": deviceTokenString]
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { return }
        } catch {
            print("デバイストークン登録エラー: \(error)")
        }
    }
    
    func checkAndRegisterPendingDeviceToken() async {
        if let token = UserDefaults.standard.string(forKey: "pendingDeviceToken") {
            await registerDeviceToken(deviceTokenString: token)
            UserDefaults.standard.removeObject(forKey: "pendingDeviceToken")
        }
    }
    
    func handleSignIn() {
        Task {
            await fetchBookmarks()
            await fetchBlocklist()
            await checkAndRegisterPendingDeviceToken()
        }
    }
    
    func handleSignOut() {
        bookmarkedQuestionIds = []
        blockedUserIds = []
        myQuestions = []
        userStats = nil
        userNicknames = [:]
        userProfileImages = [:]
        answerLogs = []
        myGradedAnswers = []
        failedAt = [:]
        inFlightNicknameTasks.values.forEach { $0.cancel() }
        inFlightNicknameTasks = [:]
    }
}
