import Foundation
import Combine

// ★★★ 修正: AnswerLog 構造体に answers を追加 ★★★
struct AnswerLog: Codable {
    let questionId: String
    let userId: String
    // selectedChoiceId は古い形式なのでオプショナルにするか、削除しても良いが
    // 新しい形式に合わせて answers (辞書) を追加
    let answers: [String: String]
    
    // (古いコードとの互換性のため残す場合)
    // let selectedChoiceId: String?
    // let isCorrect: Bool?
}

struct AnswerStatus: Codable {
    let hasAnswered: Bool
}

@MainActor
class QuizViewModel: ObservableObject {

    @Published var isLoading = false {
        didSet {
            print("QuizViewModel: isLoading changed to \(isLoading)")
        }
    }

    private let answersApiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/answers")!

    private var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    private func getAuthToken() async -> String? {
        guard let authVM = self.authViewModel else {
            print("QuizViewModel: AuthViewModelが設定されていません。")
            return nil
        }
        return await authVM.getValidIdToken()
    }

    // ★★★ 修正: submitAllAnswers 関数を追加 (前回の提案コード) ★★★
    func submitAllAnswers(questionId: String, answers: [String: Any]) async -> Bool {
        guard let userId = authViewModel?.userSub,
              let idToken = await getAuthToken() else {
            print("回答送信: 未ログインまたはトークン取得失敗")
            return false
        }
        
        isLoading = true
        print("回答送信開始: \(questionId)")
        
        // Any型をStringに変換して辞書を作る
        var jsonCompatibleAnswers: [String: String] = [:]
        for (key, value) in answers {
            jsonCompatibleAnswers[key] = String(describing: value)
        }
        
        // AnswerLog構造体を使ってエンコード
        let log = AnswerLog(questionId: questionId, userId: userId, answers: jsonCompatibleAnswers)
        
        do {
            var request = URLRequest(url: answersApiEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(log)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                print("回答送信成功！")
                isLoading = false
                return true
            } else {
                print("回答送信エラー: \(response)")
                isLoading = false
                return false
            }
        } catch {
            print("回答送信例外: \(error)")
            isLoading = false
            return false
        }
    }

    func checkIfAlreadyAnswered(questionId: String) async -> Bool {
        print("QuizViewModel: checkIfAlreadyAnswered started for questionId: \(questionId)")
        
        guard let idToken = await getAuthToken() else {
            print("解答状況確認: 認証トークン取得失敗（未ログインまたはエラー）")
            return false
        }
        
        isLoading = true

        var urlComponents = URLComponents(url: answersApiEndpoint.appendingPathComponent("status"), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "questionId", value: questionId)]

        guard let url = urlComponents?.url else {
            print("QuizViewModel: 解答状況確認URLの作成に失敗")
            isLoading = false
            return false
        }

        var result = false
        do {
            var request = URLRequest(url: url)
            request.setValue(idToken, forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("QuizViewModel: 解答状況確認時にサーバーエラー: \(response)")
                isLoading = false
                return false
            }

            let status = try JSONDecoder().decode(AnswerStatus.self, from: data)
            print("QuizViewModel: 解答状況確認成功: \(status.hasAnswered)")
            result = status.hasAnswered

        } catch {
            print("QuizViewModel: 解答状況の確認またはデコードに失敗: \(error)")
            result = false
        }

        isLoading = false
        return result
    }
    
    // (旧 logAnswer 関数は削除または非推奨にする)
    func logAnswer(questionId: String, userId: String?, selectedChoiceId: String, isCorrect: Bool) async {
        print("⚠️ logAnswer is deprecated. Use submitAllAnswers instead.")
    }
    
    func reportQuizCompletion(questionId: String, score: Int, totalQuestions: Int) async {
        // (この関数は主に分析用に使われていたものですが、新しいフローでは submitAllAnswers で兼ねることも可能です)
        // 必要なら残しておいてください
    }
}

