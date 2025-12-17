import Foundation
import Combine

// ブロック確認APIのレスポンス用
struct BlockCheckResponse: Decodable {
    let isBlockedByTarget: Bool
}

// レスポンスのスレッドID用（最小構成）
struct MinimalThreadId: Codable {
    let threadId: String
}

@MainActor
class DMViewModel: ObservableObject {

    @Published var threads: [DMThread] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    // エラーハンドリング用（NGワードチェックやブロック通知で使用）
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    // APIエンドポイント定義
    private let dmsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/dms")!
    private let threadsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/threads")!
    private let usersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/users")!

    // --- Auth 連携 ---
    private var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    private func getAuthToken() async -> String? {
        return await authViewModel?.getValidIdToken()
    }
    
    // MARK: - スレッド取得・検索
    
    // 特定のユーザーとのスレッドを取得（メモリ内検索 -> なければAPI取得）
    func findDMThread(with targetUserId: String) async -> DMThread? {
        guard let myId = authViewModel?.userSub else { return nil }
        
        // ローカルにデータがなければ取得
        if threads.isEmpty {
            await fetchThreads(userId: myId)
        }
        
        // メモリ上で検索
        if let existing = threads.first(where: { $0.participants.contains(targetUserId) }) {
            return existing
        }
        
        // 見つからなければサーバーから最新を取得して再検索
        await fetchThreads(userId: myId)
        return threads.first(where: { $0.participants.contains(targetUserId) })
    }
    
    // スレッド一覧を取得 API: GET /threads
    func fetchThreads(userId: String) async {
        guard !userId.isEmpty else { return }
        guard let idToken = await getAuthToken() else { return }

        isLoading = true
        defer { isLoading = false }

        var comps = URLComponents(url: threadsEndpoint, resolvingAgainstBaseURL: true)
        comps?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = comps?.url else { return }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            self.threads = try JSONDecoder().decode([DMThread].self, from: data)
        } catch {
            print("Fetch threads failed: \(error)")
        }
    }
    
    // MARK: - メッセージ取得
    
    // メッセージ一覧取得 API: GET /threads/{id}/messages
    func fetchMessages(threadId: String) async {
        guard !threadId.isEmpty else { return }
        guard let idToken = await getAuthToken() else {
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        let url = threadsEndpoint.appendingPathComponent(threadId).appendingPathComponent("messages")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            self.messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            print("Fetch messages failed: \(error)")
            self.messages = []
        }
    }

    // MARK: - 送信処理
    
    // 既存のシンプルな送信メソッド（成功可否のみ返す）
    // 会話画面などで使用されます
    func sendMessage(recipientId: String, senderId: String, questionTitle: String, messageText: String) async -> Bool {
        // NGワードチェック
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = NGWordFilter.shared.check(trimmedText)
        
        if case .blocked(let reason) = result {
            self.errorMessage = reason
            self.showError = true
            return false
        }
        
        // 実際には下で定義するメソッドを呼ぶが、戻り値をBoolにする
        let thread = await sendInitialDMAndReturnThread(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText)
        return thread != nil
    }

    // ★★★ InitialDMView / ConversationView から呼ばれる高機能送信メソッド ★★★
    // スレッドオブジェクトを返すため、送信後の画面遷移に使えます
    func sendInitialDMAndReturnThread(recipientId: String,
                                      senderId: String,
                                      questionTitle: String,
                                      messageText: String,
                                      voiceData: Data? = nil,
                                      duration: Double? = nil,
                                      imageData: Data? = nil
    ) async -> DMThread? {
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
            return nil
        }
        
        if isBlocked == true {
            print("DM送信中止: 相手からブロックされています。")
            self.errorMessage = "相手からブロックされているため送信できません"
            self.showError = true
            return nil
        }

        // --- 2. DMを送信 ---
        var messageType = "text"
        if voiceData != nil {
            messageType = "voice"
        } else if imageData != nil {
            messageType = "image"
        }
        
        let dmPayload = DM(
            recipientId: recipientId,
            senderId: senderId,
            questionTitle: questionTitle,
            messageText: messageText,
            messageType: messageType,
            voiceBase64: voiceData?.base64EncodedString(),
            voiceDuration: duration,
            imageBase64: imageData?.base64EncodedString()
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
                return nil
            }

            // 成功時のレスポンス処理
            
            // パターンA: スレッドそのものが返ってくる場合
            if let t = try? JSONDecoder().decode(DMThread.self, from: data) {
                return t
            }

            // パターンB: { "threadId": "..." } だけが返ってくる場合
            var returnedThreadId: String? = nil
            if let m = try? JSONDecoder().decode(MinimalThreadId.self, from: data) {
                returnedThreadId = m.threadId
            }

            // スレッドを特定するために一覧を再取得（フォールバック）
            if let myUserId = authViewModel?.userSub {
                // 少し待機（DB反映待ち）
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                
                await fetchThreads(userId: myUserId)
                
                // threadIdで検索
                if let tid = returnedThreadId, let found = threads.first(where: { $0.threadId == tid }) {
                    return found
                }
                
                // 見つからなければ参加者ペアとタイトルで検索
                let pairSet = Set([recipientId, senderId])
                // 最新のものから探す
                if let found = threads.sorted(by: { $0.lastUpdated > $1.lastUpdated })
                    .first(where: { Set($0.participants) == pairSet }) {
                    return found
                }
            }

            return nil

        } catch {
            print("DM送信エラー: \(error)")
            return nil
        }
    }
    
    // MARK: - 内部ヘルパー
    
    // ブロック確認 API: GET /users/check-block
    private func checkIfBlockedByTarget(targetId: String) async -> Bool? {
        guard let idToken = await getAuthToken() else { return nil }
        
        var comps = URLComponents(url: usersApiEndpoint.appendingPathComponent("check-block"), resolvingAgainstBaseURL: true)
        comps?.queryItems = [URLQueryItem(name: "targetId", value: targetId)]
        guard let url = comps?.url else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let result = try JSONDecoder().decode(BlockCheckResponse.self, from: data)
            return result.isBlockedByTarget
        } catch {
            return nil
        }
    }
}
