import Foundation

/// API呼び出しの共通処理
struct APIClient {
    
    /// ネットワークチェック付きのリクエスト実行
    static func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        headers:  [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        
        // オフラインチェック
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.unknown(message: "無効なレスポンス")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // エラーレスポンスをパース
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AppError.fromStatusCode(httpResponse.statusCode, message: errorResponse.message)
                }
                throw AppError.fromStatusCode(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("デコードエラー: \(error)")
                throw AppError.decodingError
            }
            
        } catch let error as AppError {
            throw error
        } catch {
            if (error as NSError).domain == NSURLErrorDomain {
                throw AppError.networkError
            }
            throw AppError.unknown(message: error.localizedDescription)
        }
    }
    
    private struct ErrorResponse: Decodable {
        let message:  String
    }
}
