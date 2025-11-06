import Foundation
import Combine

@MainActor
class DMViewModel: ObservableObject {

    @Published var threads: [Thread] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false

    // 既存エンドポイント
    private let dmsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/dms")!
    private let threadsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/threads")!

    // --- Auth 連携 ---
    private var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    // トークン取得
    private func getAuthToken() async -> String? {
        guard let authVM = self.authViewModel else {
            print("DMViewModel: AuthViewModelが設定されていません。")
            return nil
        }
        return await authVM.getValidIdToken()
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

            let decoded = try JSONDecoder().decode([Thread].self, from: data)
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
        return await sendInitialDM(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText)
    }

    // 最小レスポンス用（{ "threadId": "..." } に対応）
    private struct MinimalThreadId: Codable { let threadId: String }

    // 初回DM送信して Thread を返す（POST /dev/dms）
    func sendInitialDMAndReturnThread(recipientId: String,
                                      senderId: String,
                                      questionTitle: String,
                                      messageText: String) async -> Thread? {
        guard let idToken = await getAuthToken() else {
            print("DM送信: 認証トークン取得失敗")
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        let dmPayload = DM(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText)

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

            // 1) APIがThread相当JSONを返す場合
            if let t = try? JSONDecoder().decode(Thread.self, from: data) {
                print("DM送信に成功（ThreadデコードOK）。threadId=\(t.threadId)")
                return t
            }

            // 2) 最小構成 { "threadId": "..." } を返す場合
            var returnedThreadId: String? = nil
            if let m = try? JSONDecoder().decode(MinimalThreadId.self, from: data) {
                returnedThreadId = m.threadId
            }

            // 3) フォールバック: 遅延後に一覧から特定（2回まで）
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
