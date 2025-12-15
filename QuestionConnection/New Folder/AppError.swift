import Foundation

/// アプリ全体で使用するエラー型
enum AppError: Error, LocalizedError {
    case networkError
    case serverError(statusCode: Int)
    case authError
    case decodingError
    case notFound
    case forbidden
    case ngWordDetected(reason: String)
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        case . networkError:
            return "インターネットに接続されていません"
        case .serverError(let statusCode):
            return "サーバーエラーが発生しました (コード: \(statusCode))"
        case .authError:
            return "認証に失敗しました。再ログインしてください"
        case .decodingError:
            return "データの読み込みに失敗しました"
        case .notFound:
            return "データが見つかりませんでした"
        case .forbidden:
            return "アクセスが拒否されました"
        case .ngWordDetected(let reason):
            return reason
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Wi-Fiまたはモバイルデータ通信をオンにしてください"
        case .serverError:
            return "しばらく時間をおいて再度お試しください"
        case .authError:
            return "ログイン画面からログインし直してください"
        case . decodingError, .notFound, .unknown:
            return "問題が解決しない場合はアプリを再起動してください"
        case .forbidden:
            return "この操作を行う権限がありません"
        case .ngWordDetected:
            return "内容を修正して再度お試しください"
        }
    }
    
    var icon: String {
        switch self {
        case .networkError:
            return "wifi.slash"
        case .serverError:
            return "exclamationmark.icloud"
        case .authError:
            return "person.crop.circle. badge.exclamationmark"
        case .decodingError, .notFound, .unknown:
            return "exclamationmark. triangle"
        case .forbidden:
            return "lock.shield"
        case .ngWordDetected:
            return "nosign"
        }
    }
    
    /// HTTPステータスコードからエラーを生成
    static func fromStatusCode(_ statusCode: Int, message: String?  = nil) -> AppError {
        switch statusCode {
        case 401:
            return .authError
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 400:
            return .unknown(message: message ?? "リクエストエラー")
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .unknown(message: message ?? "エラーが発生しました")
        }
    }
}
