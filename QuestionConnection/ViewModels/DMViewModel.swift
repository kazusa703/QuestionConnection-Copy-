import Foundation
import Combine

@MainActor
class DMViewModel: ObservableObject {

    @Published var threads: [Thread] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false

    private let dmsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/dms")!
    private let threadsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/threads")!

    func fetchMessages(threadId: String, idToken: String) async {
        guard !threadId.isEmpty else { return }
        isLoading = true
        let url = threadsEndpoint.appendingPathComponent(threadId).appendingPathComponent("messages")
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("メッセージ一覧取得時にサーバーエラー: \(response)")
                isLoading = false
                return
            }
            self.messages = try JSONDecoder().decode([Message].self, from: data)
            print("メッセージ一覧の取得に成功。件数: \(messages.count)")
        } catch {
            print("メッセージ一覧の取得またはデコードに失敗: \(error)")
            self.messages = []
        }
        isLoading = false
    }

    // sendMessageはsendInitialDMを呼び出すだけなので変更不要
    func sendMessage(recipientId: String, senderId: String, questionTitle: String, messageText: String, idToken: String) async -> Bool {
         return await sendInitialDM(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText, idToken: idToken)
    }

    func fetchThreads(userId: String, idToken: String) async {
        guard !userId.isEmpty else { return }
        isLoading = true
        var urlComponents = URLComponents(url: threadsEndpoint, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = urlComponents?.url else {
            print("URLの作成に失敗")
            isLoading = false
            return
        }
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("スレッド一覧取得時にサーバーエラー: \(response)")
                isLoading = false
                return
            }
            self.threads = try JSONDecoder().decode([Thread].self, from: data)
            print("スレッド一覧の取得に成功。件数: \(threads.count)")
        } catch {
            print("スレッド一覧の取得またはデコードに失敗: \(error)")
        }
        isLoading = false
    }

    // 最初のDMを送信する関数 (★★★ここを修正★★★)
    func sendInitialDM(recipientId: String, senderId: String, questionTitle: String, messageText: String, idToken: String) async -> Bool {
        isLoading = true
        let dmPayload = DM(recipientId: recipientId, senderId: senderId, questionTitle: questionTitle, messageText: messageText)
        do {
            var request = URLRequest(url: dmsEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(dmPayload)
            let (_, response) = try await URLSession.shared.data(for: request)

            // ★★★ 修正点: 200 または 201 であれば成功とみなす ★★★
            guard let httpResponse = response as? HTTPURLResponse,
                  (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
                print("DM送信時に予期せぬステータスコード: \(response)") // エラーメッセージも変更
                isLoading = false
                return false
            }

            print("DM送信に成功しました！(Status Code: \(httpResponse.statusCode))") // 成功時のログも改善
            isLoading = false
            return true
        } catch {
            print("DM送信APIへのリクエスト中にエラー: \(error)")
            isLoading = false
            return false
        }
    }
}
