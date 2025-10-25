import Foundation
import Combine

struct AnswerLog: Codable {
    let questionId: String
    let userId: String
    let selectedChoiceId: String
    let isCorrect: Bool
}
struct AnswerStatus: Codable {
    let hasAnswered: Bool
}

@MainActor
class QuizViewModel: ObservableObject {

    @Published var isLoading = false {
        // ★★★ isLoading の変更をコンソールに出力 ★★★
        didSet {
            print("QuizViewModel: isLoading changed to \(isLoading)")
        }
    }

    private let answersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/answers")!

    func checkIfAlreadyAnswered(questionId: String, idToken: String) async -> Bool {
        print("QuizViewModel: checkIfAlreadyAnswered started for questionId: \(questionId)") // ★★★ 開始ログ
        isLoading = true

        var urlComponents = URLComponents(url: answersApiEndpoint.appendingPathComponent("status"), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "questionId", value: questionId)]

        guard let url = urlComponents?.url else {
            print("QuizViewModel: 解答状況確認URLの作成に失敗")
            isLoading = false
            return true
        }

        var result = true // デフォルトは解答済み扱い
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("QuizViewModel: 解答状況確認時にサーバーエラー: \(response)")
                isLoading = false
                return true
            }

            let status = try JSONDecoder().decode(AnswerStatus.self, from: data)
            print("QuizViewModel: 解答状況確認成功: \(status.hasAnswered)")
            result = status.hasAnswered // 結果を保存

        } catch {
            print("QuizViewModel: 解答状況の確認またはデコードに失敗: \(error)")
            result = true // エラー時も解答済み扱い
        }

        isLoading = false
        print("QuizViewModel: checkIfAlreadyAnswered finished, returning \(result)") // ★★★ 終了ログ
        return result
    }

    func logAnswer(questionId: String, userId: String?, selectedChoiceId: String, isCorrect: Bool, idToken: String?) async {
        guard let userId = userId, let idToken = idToken else {
            print("QuizViewModel: 未ログインのため回答を記録しません。")
            return
        }
        print("QuizViewModel: logAnswer started") // ★★★ 開始ログ
        isLoading = true
        let log = AnswerLog(questionId: questionId, userId: userId, selectedChoiceId: selectedChoiceId, isCorrect: isCorrect)
        do {
            var request = URLRequest(url: answersApiEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(log)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("QuizViewModel: 回答ログの記録に成功しました！")
            } else {
                print("QuizViewModel: 回答ログ記録時にサーバーエラー: \(response)")
            }
        } catch {
            print("QuizViewModel: 回答ログ記録APIへのリクエスト中にエラー: \(error)")
        }
         isLoading = false
         print("QuizViewModel: logAnswer finished") // ★★★ 終了ログ
    }
}
