import Foundation
import Combine

@MainActor
class QuestionViewModel: ObservableObject {

    @Published var questions: [Question] = []
    @Published var isLoading = false
    
    // 目的選択肢（拡張版）
    let availablePurposes: [String] = [
        "楽しむ",
        "学ぶ",
        "教える",
        "挑戦する",
        "仲間探し",
        "暇つぶし",
        "議論する",
        "共有する",
        "意見を知る"
    ]

    private var apiEndpoint: URL {
        return URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/questions")!
    }

    // AuthViewModelを保持
    private var authViewModel: AuthViewModel?

    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    private func getAuthToken() async -> String? {
        guard let authVM = self.authViewModel else {
            print("QuestionViewModel: AuthViewModelが設定されていません。")
            return nil
        }
        return await authVM.getValidIdToken()
    }

    // 一覧取得（目的・ブックマーク対応）
    func fetchQuestions(purpose: String? = nil, bookmarkedBy userId: String? = nil) async {
        isLoading = true
        
        var urlComponents = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)
        var queryItems: [URLQueryItem] = []
        
        if let purpose = purpose, !purpose.isEmpty {
            queryItems.append(URLQueryItem(name: "purpose", value: purpose))
        }
        if let userId = userId, !userId.isEmpty {
            queryItems.append(URLQueryItem(name: "bookmarkedBy", value: userId))
            print("ブックマークフィルターを適用: userId=\(userId)")
        }
        if !queryItems.isEmpty { urlComponents?.queryItems = queryItems }
        guard let url = urlComponents?.url else {
            print("URLの作成に失敗しました。")
            isLoading = false
            return
        }

        print("Fetching questions from URL: \(url.absoluteString)")

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

    // POST用DTO（サーバー生成項目は含めない）
    private struct CreateQuestionRequest: Codable {
        let title: String
        let purpose: String?
        let tags: [String]
        let remarks: String
        let authorId: String
        let quizItems: [QuizItem]
        let dmInviteMessage: String? // 追加
    }

    // 質問作成（dmInviteMessage を追加）
    func createQuestion(title: String,
                        tags: [String],
                        remarks: String,
                        authorId: String,
                        quizItems: [QuizItem],
                        purpose: String,
                        dmInviteMessage: String? = nil) async -> Bool {
        isLoading = true

        guard let idToken = await getAuthToken() else {
            print("質問作成: 認証トークン取得失敗")
            isLoading = false
            return false
        }

        let payload = CreateQuestionRequest(
            title: title,
            purpose: purpose.isEmpty ? nil : purpose,
            tags: tags,
            remarks: remarks,
            authorId: authorId,
            quizItems: quizItems,
            dmInviteMessage: (dmInviteMessage?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        )

        do {
            var request = URLRequest(url: apiEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(idToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(payload)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                print("サーバーからのエラー応答: \(response)")
                isLoading = false
                return false
            }

            print("質問の投稿に成功しました！")
            isLoading = false
            return true

        } catch {
            print("APIへのリクエスト中にエラーが発生しました: \(error)")
            isLoading = false
            return false
        }
    }
}
