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
        // isLoading の変更をコンソールに出力
        didSet {
            print("QuizViewModel: isLoading changed to \(isLoading)")
        }
    }

    private let answersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/answers")!

    // --- ★★★ ここから修正 ★★★ ---
    // AuthViewModelを保持 (オプショナル)
    private var authViewModel: AuthViewModel?

    // AuthViewModelを設定するメソッド
    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // 内部で認証トークンを取得するヘルパー
    private func getAuthToken() async -> String? {
        guard let authVM = self.authViewModel else {
            print("QuizViewModel: AuthViewModelが設定されていません。")
            return nil
        }
        // AuthViewModelが持つトークン取得メソッドを呼び出す（ここでは仮にgetValidIdTokenとする）
        return await authVM.getValidIdToken()
    }
    // --- ★★★ ここまで修正 ★★★ ---

    // ★★★ idToken 引数を削除 ★★★
    func checkIfAlreadyAnswered(questionId: String) async -> Bool {
        print("QuizViewModel: checkIfAlreadyAnswered started for questionId: \(questionId)")
        
        // ★★★ 関数内で getAuthToken を呼び出す ★★★
        guard let idToken = await getAuthToken() else {
            print("解答状況確認: 認証トークン取得失敗（未ログインまたはエラー）")
            // ログインしていない場合（トークン取得失敗）は「未解答」扱い
            return false
        }
        
        isLoading = true

        var urlComponents = URLComponents(url: answersApiEndpoint.appendingPathComponent("status"), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "questionId", value: questionId)]

        guard let url = urlComponents?.url else {
            print("QuizViewModel: 解答状況確認URLの作成に失敗")
            isLoading = false
            return false // エラー時は false
        }

        var result = false // デフォルトは false
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("QuizViewModel: 解答状況確認時にサーバーエラー: \(response)")
                isLoading = false
                return false // エラー時は false
            }

            let status = try JSONDecoder().decode(AnswerStatus.self, from: data)
            print("QuizViewModel: 解答状況確認成功: \(status.hasAnswered)")
            result = status.hasAnswered

        } catch {
            print("QuizViewModel: 解答状況の確認またはデコードに失敗: \(error)")
            result = false // エラー時も false
        }

        isLoading = false
        print("QuizViewModel: checkIfAlreadyAnswered finished, returning \(result)")
        return result
    }

    // ★★★ idToken 引数を削除 ★★★
    func logAnswer(questionId: String, userId: String?, selectedChoiceId: String, isCorrect: Bool) async {
        
        // ★★★ 関数内で getAuthToken と userId を呼び出す ★★★
        guard let authVM = self.authViewModel,
              // AuthViewModelから現在のユーザーIDを取得
              let userId = authVM.userSub,
              let idToken = await getAuthToken() else {
            print("QuizViewModel: 未ログインのため回答を記録しません。")
            return
        }
        
        print("QuizViewModel: logAnswer started")
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
        print("QuizViewModel: logAnswer finished")
    }
    
    // ★★★ 追加: クイズ完了をサーバーに報告する関数 ★★★
    func reportQuizCompletion(questionId: String, score: Int, totalQuestions: Int) async {
        // 全問正解でない場合はAPIを呼び出す必要はない
        guard score == totalQuestions else {
            print("QuizViewModel: Not a perfect score, skipping report.")
            return
        }
        
        // 認証情報を取得
        guard let authVM = self.authViewModel,
              let idToken = await authVM.getValidIdToken() else {
            print("QuizViewModel: Not signed in, skipping report.")
            return
        }
        
        print("QuizViewModel: Reporting perfect score to server...")

        // APIエンドポイント (例: .../questions/{questionId}/complete)
        let urlString = "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions/\(questionId)/complete"
        guard let url = URL(string: urlString) else {
            print("QuizViewModel: Invalid URL for reportQuizCompletion")
            return
        }
        
        // リクエストボディ
        let requestBody = ["score": score, "totalQuestions": totalQuestions]
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("QuizViewModel: Quiz completion reported successfully.")
            } else {
                print("QuizViewModel: Failed to report quiz completion. Response: \(response)")
            }
        } catch {
            print("QuizViewModel: Error reporting quiz completion: \(error)")
        }
    }
}

