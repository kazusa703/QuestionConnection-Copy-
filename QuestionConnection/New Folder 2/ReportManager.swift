import Foundation

/// 通報結果
enum ReportResult {
    case success
    case alreadyReported
    case failure(message: String)
}

/// 通報管理クラス
final class ReportManager {
    
    static let shared = ReportManager()
    
    private let apiEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/reports")!
    
    private init() {}
    
    /// 通報を送信
    func submitReport(
        reporterId:  String,
        targetType: ReportTargetType,
        targetId: String,
        reason:  ReportReason,
        reasonDetail: String,
        idToken: String?
    ) async -> ReportResult {
        
        let body:  [String: Any] = [
            "reporterId": reporterId,
            "targetType": targetType.rawValue,
            "targetId": targetId,
            "reason": reason.rawValue,
            "reasonDetail": reasonDetail.trimmingCharacters(in: . whitespacesAndNewlines)
        ]
        
        do {
            var request = URLRequest(url: apiEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = idToken {
                request.setValue(token, forHTTPHeaderField: "Authorization")
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("📤 通報送信:  \(targetType.rawValue)/\(targetId)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("📥 通報レスポンス: \(http.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 レスポンス内容: \(responseString)")
                }
                
                switch http.statusCode {
                case 201:
                    return .success
                case 409:
                    return .alreadyReported
                case 400:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        return .failure(message: errorResponse.message)
                    }
                    return .failure(message: "リクエストエラー")
                case 401, 403:
                    return . failure(message: "認証エラー。再ログインしてください")
                default:
                    return .failure(message: "サーバーエラーが発生しました")
                }
            }
        } catch {
            print("❌ 通報エラー: \(error)")
            return .failure(message: "通信エラーが発生しました")
        }
        
        return .failure(message: "不明なエラー")
    }
    
    private struct ErrorResponse: Decodable {
        let message:  String
    }
}
