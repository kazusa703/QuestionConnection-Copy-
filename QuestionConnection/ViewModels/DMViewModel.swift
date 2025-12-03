import Foundation
import Combine

// ブロック確認APIのレスポンス用
struct BlockCheckResponse: Decodable {
    let isBlockedByTarget: Bool
}

@MainActor
class DMViewModel: ObservableObject {

    // ★★★ 修正: [Thread] -> [DMThread] ★★★
    @Published var threads: [DMThread] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false

    // 既存エンドポイント
    private let dmsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/dms")!
    private let threadsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/threads")!
    // ブロック確認用エンドポイント
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!


    // --- Auth 連携 (変更なし) ---
    private var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    private func getAuthToken() async -> String? {
        guard let authVM = self.authViewModel else {
            print("DMViewModel: AuthViewModelが設定されていません。")
            return nil
        }
        return await authVM.getValidIdToken()
    }
    
    // ★★★ 追加: 特定のユーザーとのスレッドを取得するメソッド ★★★
    func findDMThread(with targetUserId: String) async -> DMThread? {
            guard let myId = authViewModel?.userSub else { return nil }
            
            // まだスレッド一覧がなければ取得
            if threads.isEmpty {
                await fetchThreads(userId: myId)
            }
            
            // 相手が含まれるスレッドを探す
            if let existing = threads.first(where: { $0.participants.contains(targetUserId) }) {
                return existing
            }
            
            // 念のため再取得して確認
            await fetchThreads(userId: myId)
            return threads.first(where: { $0.participants.contains(targetUserId) })
        }
    
    // ブロック確認関数
    private func checkIfBlockedByTarget(targetId: String) async -> Bool? {
        guard let idToken = await getAuthToken() else {
            print("ブロック確認: 認証トークン取得失敗")
            return nil // エラー
        }
        
        // GET /users/check-block?targetId={targetId}
        var comps = URLComponents(url: usersApiEndpoint.appendingPathComponent("check-block"), resolvingAgainstBaseURL: true)
        comps?.queryItems = [URLQueryItem(name: "targetId", value: targetId)]
        
        guard let url = comps?.url else {
            print("ブロック確認: URL生成失敗")
            return nil // エラー
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 1. まず HTTPURLResponse にキャストできるか確認
            guard let http = response as? HTTPURLResponse else {
                print("ブロック確認API: 不正なレスポンス（HTTPレスポンスではありません）")
                return nil // エラー
            }
            
            // 2. 次にステータスコードを確認
            guard http.statusCode == 200 else {
                let snippet = String(data: data, encoding: .utf8) ?? ""
                print("ブロック確認API時にサーバーエラー: \(http.statusCode) body: \(snippet.prefix(200))")
                return nil // エラー
            }

            let result = try JSONDecoder().decode(BlockCheckResponse.self, from: data)
            return result.isBlockedByTarget // true または false

        } catch {
            print("ブロック確認APIの取得またはデコードに失敗: \(error)")
            return nil // エラー
        }
    }
    

    // メッセージ一覧を取得: GET /threads/{threadId}/messages
    func fetchMessages(threadId: String) async {
        guard !threadId.isEmpty else { return }
        guard let idToken = await getAuthToken() else {
            print("メッセージ一覧取得: 認証トークン取得失敗")
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        let url = threadsEndpoint
            .appendingPathComponent(threadId)
            .appendingPathComponent("messages")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                print("メッセージ一覧取得: 不正なレスポンス")
                return
            }
            guard http.statusCode == 200 else {
                let snippet = String(data: data, encoding: .utf8) ?? ""
                print("メッセージ一覧取得時にサーバーエラー: \(http.statusCode) body: \(snippet.prefix(200))")
                return
            }

            self.messages = try JSONDecoder().decode([Message].self, from: data)
            print("メッセージ一覧の取得に成功。件数: \(messages.count)")
        } catch {
            print("メッセージ一覧の取得またはデコードに失敗: \(error)")
            self.messages = []
        }
    }

    // スレッド一覧を取得: GET /threads?userId=...
    func fetchThreads(userId: String) async {
        guard !userId.isEmpty else { return }
        guard let idToken = await getAuthToken() else {
            print("スレッド一覧取得: 認証トークン取得失敗")
            return
        }

        isLoading = true
        defer { isLoading = false }

        var comps = URLComponents(url: threadsEndpoint, resolvingAgainstBaseURL: true)
        comps?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = comps?.url else {
            print("スレッド一覧取得: URL生成失敗")
            return
        }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                print("スレッド一覧取得: 不正なレスポンス")
                return
            }
            guard http.statusCode == 200 else {
                let snippet = String(data: data, encoding: .utf8) ?? ""
                print("スレッド一覧取得時にサーバーエラー: \(http.statusCode) body: \(snippet.prefix(200))")
                return
            }

            // ★★★ 修正: [DMThread] に変更 ★★★
            let decoded = try JSONDecoder().decode([DMThread].self, from: data)
            self.threads = decoded
            print("スレッド一覧の取得に成功。件数: \(decoded.count)")
        } catch {
            print("スレッド一覧の取得またはデコードに失敗: \(error)")
        }
    }

    // 初回DM（成功可否のみ）
    func sendInitialDM(recipientId: String, senderId: String, questionTitle: String, messageText: String) async -> Bool {
        if let _ = await sendInitialDMAndReturnThread(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText) {
            return true
        } else {
            return false
        }
    }

    // 既存: 会話内送信（現状は同エンドポイントを使用）
    func sendMessage(recipientId: String, senderId: String, questionTitle: String, messageText: String) async -> Bool {
        // ★注意: 既存の会話内送信も「ブロック確認」が入るようになります。
        return await sendInitialDM(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText)
    }

    // 最小レスポンス用（{ "threadId": "..." } に対応）
    struct MinimalThreadId: Codable { let threadId: String }

    // ★★★ sendInitialDMAndReturnThread 関数 (戻り値を DMThread? に変更) ★★★
    func sendInitialDMAndReturnThread(recipientId: String,
                                      senderId: String,
                                      questionTitle: String,
                                      messageText: String,
                                      voiceData: Data? = nil,
                                      duration: Double? = nil,
                                      imageData: Data? = nil
    ) async -> DMThread? {  // ★★★ 修正: Thread -> DMThread ★★★
        guard let idToken = await getAuthToken() else {
            print("DM送信: 認証トークン取得失敗")
            return nil
        }

        isLoading = true
        defer { isLoading = false }
        
        // --- 1. 送信前にブロック確認 ---
        let isBlocked = await checkIfBlockedByTarget(targetId: recipientId)
        
        if isBlocked == nil {
            print("DM送信中止: ブロック状態の確認に失敗しました。")
            return nil // エラー
        }
        
        if isBlocked == true {
            print("DM送信中止: 相手からブロックされています。")
            return nil
        }
        // --- ブロック確認ここまで ---


        // --- 2. ブロックされていなければDMを送信 ---
        var messageType = "text"
        if voiceData != nil {
            messageType = "voice"
        } else if imageData != nil {
            messageType = "image"
        }
        
        // データをBase64に変換
        let voiceBase64String = voiceData?.base64EncodedString()
        let imageBase64String = imageData?.base64EncodedString()
        
        let dmPayload = DM(
            recipientId: recipientId,
            senderId: senderId,
            questionTitle: questionTitle,
            messageText: messageText,
            messageType: messageType,
            voiceBase64: voiceBase64String,
            voiceDuration: duration,
            imageBase64: imageBase64String
        )

        do {
            var request = URLRequest(url: dmsEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(dmPayload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (http.statusCode == 200 || http.statusCode == 201) else {
                let snippet = String(data: data, encoding: .utf8) ?? ""
                print("DM送信時に予期せぬステータスコード: \(String(describing: (response as? HTTPURLResponse)?.statusCode)) body: \(snippet.prefix(200))")
                return nil
            }

            // 1) APIが Thread 相当JSONを返す場合
            // ★★★ 修正: DMThread でデコード ★★★
            if let t = try? JSONDecoder().decode(DMThread.self, from: data) {
                print("DM送信に成功（ThreadデコードOK）。threadId=\(t.threadId)")
                return t
            }

            // 2) 最小構成 { "threadId": "..." } を返す場合
            var returnedThreadId: String? = nil
            if let m = try? JSONDecoder().decode(MinimalThreadId.self, from: data) {
                returnedThreadId = m.threadId
            }

            // 3) フォールバック
            if let myUserId = authViewModel?.userSub {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                for attempt in 1...2 {
                    await fetchThreads(userId: myUserId)
                    if let tid = returnedThreadId, let found = threads.first(where: { $0.threadId == tid }) {
                        print("DM送信フォールバック成功(id一致, attempt \(attempt)) threadId=\(found.threadId)")
                        return found
                    }
                    let pairSet = Set([recipientId, senderId])
                    if let byPairAndTitle = threads
                        .filter({ Set($0.participants) == pairSet && $0.questionTitle == questionTitle })
                        .max(by: { $0.lastUpdated < $1.lastUpdated }) {
                        print("DM送信フォールバック成功(pair+title, attempt \(attempt)) threadId=\(byPairAndTitle.threadId)")
                        return byPairAndTitle
                    }
                    if let byPairOnly = threads
                        .filter({ Set($0.participants) == pairSet })
                        .max(by: { $0.lastUpdated < $1.lastUpdated }) {
                        print("DM送信フォールバック成功(pairのみ, attempt \(attempt)) threadId=\(byPairOnly.threadId)")
                        return byPairOnly
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                }
            }

            print("DM送信は成功した可能性があるが、Threadの特定に失敗しました。")
            return nil

        } catch {
            print("DM送信APIへのリクエスト中にエラー: \(error)")
            return nil
        }
    }
}
