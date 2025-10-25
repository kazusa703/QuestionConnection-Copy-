import Foundation
import AWSCognitoIdentityProvider
import Combine
import AWSClientRuntime

// MARK: - Model Structs for JWT Claims

// JWTからデコードした情報を持つ構造体
struct AuthClaims {
    let sub: String
    let username: String
    let email: String
    let exp: Date // ★★★ 有効期限(exp)をDate型で保持するよう変更 ★★★
    // JSONとして取得した全クレーム
    let rawClaims: [String: Any]
}

// MARK: - AuthViewModel

@MainActor
class AuthViewModel: ObservableObject {

    @Published var isSignedIn = false
    @Published var userSub: String?
    @Published var idToken: String?
    @Published var userEmail: String?

    private let userPoolId = "ap-northeast-1_yXUIT8alc"
    private let clientId = "8rma5ritn3n6c061kco5j753c"
    private let region: String = "ap-northeast-1"
    private let cognitoClient: CognitoIdentityProviderClient

    init() {
        do {
            // リージョンを指定してCognitoクライアントを初期化
            self.cognitoClient = try CognitoIdentityProviderClient(region: self.region)
        } catch {
            fatalError("Cognitoクライアントの初期化に失敗: \(error)")
        }
        // アプリ起動時にログイン状態を確認
        Task {
            await checkCurrentSession()
        }
        print("AuthViewModel initialized.")
    }

    // MARK: - Session Management

    // トークン情報から現在のログイン状態を確認・復元
    func checkCurrentSession() async {
        // --- ★★★ ここからロジックを大幅に修正 ★★★ ---
        guard let token = UserDefaults.standard.string(forKey: "IdToken"),
              let sub = UserDefaults.standard.string(forKey: "UserSub"),
              let email = UserDefaults.standard.string(forKey: "UserEmail")
        else {
            // 保存されている情報がなければサインアウト状態
            await MainActor.run { self.signOut() }
            return
        }

        // JWTをデコードし、有効期限をチェック
        if let claims = decode(jwtToken: token), claims.exp > Date() {
            // トークンが有効（期限内）の場合のみセッションを復元
            await MainActor.run {
                self.idToken = token
                self.userSub = sub
                self.userEmail = email
                self.isSignedIn = true
                print("Session resumed successfully for user: \(sub). Token is valid until \(claims.exp).")
            }
        } else {
            // トークンが無効（期限切れ）の場合はサインアウトさせる
            await MainActor.run {
                print("Session restore failed. Token is expired or invalid.")
                self.signOut()
            }
        }
        // --- ★★★ ここまで修正 ★★★ ---
    }

    // MARK: - Authentication Methods

    func signUp(email: String, password: String) async -> Bool {
        let signUpInput = SignUpInput(clientId: self.clientId, password: password, userAttributes: [ .init(name: "email", value: email) ], username: email)
        do {
            _ = try await cognitoClient.signUp(input: signUpInput)
            print("AuthViewModel: サインアップ成功")
            return true
        } catch {
            print("AuthViewModel: サインアップ失敗: \(error)")
            return false
        }
    }

    func confirmSignUp(email: String, code: String) async -> Bool {
        let input = ConfirmSignUpInput(clientId: self.clientId, confirmationCode: code, username: email)
        do {
            _ = try await cognitoClient.confirmSignUp(input: input)
            print("AuthViewModel: 本人確認成功")
            return true
        } catch {
            print("AuthViewModel: 本人確認失敗: \(error)")
            return false
        }
    }


    func signIn(email: String, password: String) async {
        print("AuthViewModel: signIn started for email: \(email)")
        let authInput = InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": email, "PASSWORD": password],
            clientId: self.clientId
        )
        do {
            print("AuthViewModel: Calling Cognito InitiateAuth...")
            let response = try await cognitoClient.initiateAuth(input: authInput)
            print("AuthViewModel: Cognito InitiateAuth response received.")

            if let authResult = response.authenticationResult, let token = authResult.idToken {
                print("AuthViewModel: AuthenticationResult received. ID Token found (length: \(token.count)).")
                
                if let claims = decode(jwtToken: token) {
                    print("AuthViewModel: JWT decoded successfully. Sub: \(claims.sub), Email: \(claims.email)")

                    // 状態とUserDefaultsを更新
                    self.idToken = token
                    self.userSub = claims.sub
                    self.userEmail = claims.email
                    self.isSignedIn = true
                    
                    UserDefaults.standard.set(token, forKey: "IdToken")
                    UserDefaults.standard.set(claims.sub, forKey: "UserSub")
                    UserDefaults.standard.set(claims.email, forKey: "UserEmail")
                    
                    print("AuthViewModel: Signed in successfully.")
                } else {
                    print("AuthViewModel: JWT decoding FAILED. Token not valid.")
                    self.signOut()
                }
            } else {
                print("AuthViewModel: AuthenticationResult or ID Token was nil in the response.")
                self.signOut()
            }
        } catch {
            print("AuthViewModel: signIn FAILED with error: \(error)")
            self.signOut()
        }
    }

    func signOut() {
        // サインアウトロジック
        self.isSignedIn = false
        self.userSub = nil
        self.idToken = nil
        self.userEmail = nil
        UserDefaults.standard.removeObject(forKey: "IdToken")
        UserDefaults.standard.removeObject(forKey: "UserSub")
        UserDefaults.standard.removeObject(forKey: "UserEmail")
        print("User signed out and session data cleared.")
    }
}

// MARK: - JWT Helper Functions (デコード処理)

// トークンの Base64URL エンコーディングをデコードし、Dataを返す
private func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: .utf8))
    let requiredPadding = Int(ceil(length / 4.0)) * 4
    let padding = requiredPadding - base64.count
    if padding > 0 {
        base64 = base64.padding(toLength: requiredPadding, withPad: "=", startingAt: 0)
    }
    return Data(base64Encoded: base64)
}

// JWTトークンを解析し、AuthClaims構造体にマッピングする
func decode(jwtToken token: String) -> AuthClaims? {
    let segments = token.components(separatedBy: ".")
    
    // JWTは3つのセグメント (ヘッダー, ペイロード, 署名) で構成される
    guard segments.count > 1,
          let payloadData = base64UrlDecode(segments[1]),
          let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any]
    else {
        print("JWT decoding failed: Invalid segment count or payload data.")
        return nil
    }
    
    // --- ★★★ ここからクレーム取得部分を修正 ★★★ ---
    // 必要なクレーム (sub, email, exp) を取得
    guard let sub = json["sub"] as? String,
          let email = json["email"] as? String,
          let expInt = json["exp"] as? TimeInterval  // expはUnixタイムスタンプ(数値)
    else {
        print("Required JWT claims (sub, email, or exp) missing.")
        return nil
    }
    
    // UnixタイムスタンプをDateオブジェクトに変換
    let expDate = Date(timeIntervalSince1970: expInt)
    
    // cognito:usernameは optionalなため、取得を試みる
    let username = (json["cognito:username"] as? String) ?? "unknown"
    
    return AuthClaims(sub: sub, username: username, email: email, exp: expDate, rawClaims: json)
    // --- ★★★ ここまで修正 ★★★ ---
}


