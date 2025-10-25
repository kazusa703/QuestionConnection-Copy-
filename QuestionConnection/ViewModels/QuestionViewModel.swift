import Foundation
import Combine

@MainActor
class QuestionViewModel: ObservableObject {

    @Published var questions: [Question] = []
    @Published var isLoading = false
    
    // 絞り込み用の選択肢リスト
    let availablePurposes: [String] = ["楽しむ", "学ぶ", "教える"]

    private var apiEndpoint: URL {
        return URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    }

    func fetchQuestions(purpose: String? = nil) async {
        isLoading = true
        
        var urlComponents = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)
        var queryItems: [URLQueryItem] = []
        
        if let purpose = purpose, !purpose.isEmpty {
            queryItems.append(URLQueryItem(name: "purpose", value: purpose))
        }
        
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            print("URLの作成に失敗しました。")
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("サーバーからの応答エラー")
                self.questions = []
                isLoading = false
                return
            }
            self.questions = try JSONDecoder().decode([Question].self, from: data)
            print("質問リストの取得に成功しました。件数: \(questions.count)")
        } catch {
            print("質問リストの取得に失敗しました: \(error)")
            self.questions = []
        }
        isLoading = false
    }

    // ★★★ ここから修正 ★★★
    func createQuestion(title: String, tags: [String], remarks: String, authorId: String, quizItems: [QuizItem], idToken: String, purpose: String) async -> Bool {
        isLoading = true

        let newQuestion = Question(
            questionId: UUID().uuidString,
            title: title,
            purpose: purpose,
            tags: tags,
            remarks: remarks,
            authorId: authorId,
            quizItems: quizItems,
            createdAt: ""
        )

        do {
            let jsonData = try JSONEncoder().encode(newQuestion)

            var request = URLRequest(url: apiEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("サーバーからのエラー応答: \(response)")
                isLoading = false
                return false // ★ 追加: エラーの場合はfalseを返す
            }

            print("質問の投稿に成功しました！")
            isLoading = false
            return true // ★ 成功の場合はtrueを返す

        } catch {
            print("APIへのリクエスト中にエラーが発生しました: \(error)")
            isLoading = false
            return false // ★ 追加: catchブロックでもfalseを返す
        }
    }
    // ★★★ ここまで修正 ★★★
}
