import Foundation
import AWSCognitoIdentityProvider // Cognito SDK
import Combine
import AWSClientRuntime

// MARK: - Model Structs for JWT Claims (変更なし)
struct AuthClaims {
    let sub: String
    let username: String
    let email: String
    let exp: Date
    let rawClaims: [String: Any]
}

// MARK: - AuthViewModel

@MainActor
class AuthViewModel: ObservableObject {

    @Published var isSignedIn = false
    @Published var userSub: String?
    @Published var idToken: String?
    @Published var userEmail: String?
    // --- ★★★ 追加: リフレッシュトークン ★★★ ---
    @Published var refreshToken: String?

    // --- UserDefaults Keys ---
    private let idTokenKey = "IdToken"
    private let userSubKey = "UserSub"
    private let userEmailKey = "UserEmail"
    // --- ★★★ 追加: リフレッシュトークン用キー ★★★ ---
    private let refreshTokenKey = "RefreshToken"


    private let userPoolId = "ap-northeast-1_yXUIT8alc" // あなたのユーザープールID
    private let clientId = "8rma5ritn3n6c061kco5j753c"    // あなたのクライアントID
    private let region: String = "ap-northeast-1"
    private let cognitoClient: CognitoIdentityProviderClient

    init() {
        do {
            self.cognitoClient = try CognitoIdentityProviderClient(region: self.region)
        } catch {
            fatalError("Cognitoクライアントの初期化に失敗: \(error)")
        }
        Task {
            // アプリ起動時にセッション状態を確認・復元
            await checkCurrentSession()
        }
        print("AuthViewModel initialized.")
    }

    // MARK: - Session Management

    /// アプリ起動時にUserDefaultsからトークンを読み込み、セッション状態を復元・検証する
    func checkCurrentSession() async {
        print("AuthViewModel: checkCurrentSession started.")
        // UserDefaultsから必要な情報を読み込む
        let storedIdToken = UserDefaults.standard.string(forKey: idTokenKey)
        let storedSub = UserDefaults.standard.string(forKey: userSubKey)
        let storedEmail = UserDefaults.standard.string(forKey: userEmailKey)
        // --- ★★★ 追加: リフレッシュトークンも読み込む ★★★ ---
        let storedRefreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)

        guard let token = storedIdToken,
              let sub = storedSub,
              let email = storedEmail,
              let refresh = storedRefreshToken // ★ リフレッシュトークンも必須とする
        else {
            print("AuthViewModel: No valid session data found in UserDefaults.")
            await MainActor.run { self.signOut() } // 必要な情報がなければサインアウト
            return
        }

        // IDトークンをデコードして有効期限をチェック
        if let claims = decode(jwtToken: token), claims.exp > Date() {
            // --- IDトークンが有効な場合 ---
            print("AuthViewModel: ID Token is valid. Resuming session.")
            await MainActor.run {
                self.idToken = token
                self.userSub = sub
                self.userEmail = email
                // --- ★★★ 追加: リフレッシュトークンもセット ★★★ ---
                self.refreshToken = refresh
                self.isSignedIn = true
                print("Session resumed successfully for user: \(sub). Token expires at \(claims.exp).")
            }
        } else {
            // --- IDトークンが無効（期限切れまたは不正）の場合 ---
            print("AuthViewModel: ID Token is expired or invalid. Attempting to refresh session...")
            // ★ リフレッシュトークンを使ってセッション更新を試みる
            let refreshed = await refreshSession(refreshToken: refresh)
            if !refreshed {
                print("AuthViewModel: Session refresh failed. Signing out.")
                await MainActor.run { self.signOut() } // リフレッシュも失敗したらサインアウト
            }
        }
        print("AuthViewModel: checkCurrentSession finished.")
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
            authFlow: .userPasswordAuth, // USER_PASSWORD_AUTH フローを使用
            authParameters: ["USERNAME": email, "PASSWORD": password],
            clientId: self.clientId
        )
        do {
            print("AuthViewModel: Calling Cognito InitiateAuth...")
            let response = try await cognitoClient.initiateAuth(input: authInput)
            print("AuthViewModel: Cognito InitiateAuth response received.")

            if let authResult = response.authenticationResult,
               let receivedIdToken = authResult.idToken,
               // --- ★★★ 追加: リフレッシュトークンを取得 ★★★ ---
               let receivedRefreshToken = authResult.refreshToken
            {
                print("AuthViewModel: AuthenticationResult received. ID Token and Refresh Token found.")

                if let claims = decode(jwtToken: receivedIdToken) {
                    print("AuthViewModel: JWT decoded successfully. Sub: \(claims.sub), Email: \(claims.email)")

                    // 状態とUserDefaultsを更新
                    self.idToken = receivedIdToken
                    self.userSub = claims.sub
                    self.userEmail = claims.email
                    // --- ★★★ 追加: リフレッシュトークンも保存 ★★★ ---
                    self.refreshToken = receivedRefreshToken
                    self.isSignedIn = true

                    UserDefaults.standard.set(receivedIdToken, forKey: idTokenKey)
                    UserDefaults.standard.set(claims.sub, forKey: userSubKey)
                    UserDefaults.standard.set(claims.email, forKey: userEmailKey)
                    // --- ★★★ 追加: リフレッシュトークンもUserDefaultsに保存 ★★★ ---
                    UserDefaults.standard.set(receivedRefreshToken, forKey: refreshTokenKey)

                    print("AuthViewModel: Signed in successfully.")
                } else {
                    print("AuthViewModel: JWT decoding FAILED. Token not valid.")
                    await MainActor.run { self.signOut() }
                }
            } else {
                print("AuthViewModel: AuthenticationResult or required tokens were nil in the response.")
                await MainActor.run { self.signOut() }
            }
        } catch {
            print("AuthViewModel: signIn FAILED with error: \(error)")
            await MainActor.run { self.signOut() }
        }
    }

    func signOut() {
        print("AuthViewModel: signOut called.")
        // --- 状態をリセット ---
        self.isSignedIn = false
        self.userSub = nil
        self.idToken = nil
        self.userEmail = nil
        // --- ★★★ 追加: リフレッシュトークンもリセット ★★★ ---
        self.refreshToken = nil

        // --- UserDefaultsから情報を削除 ---
        UserDefaults.standard.removeObject(forKey: idTokenKey)
        UserDefaults.standard.removeObject(forKey: userSubKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        // --- ★★★ 追加: リフレッシュトークンも削除 ★★★ ---
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        print("User signed out and session data cleared.")
    }

    // --- ★★★ ここからが自動更新機能 ★★★ ---

    /// リフレッシュトークンを使用してIDトークンを更新する
    /// - Parameter refreshToken: 使用するリフレッシュトークン
    /// - Returns: 更新に成功した場合は true, 失敗した場合は false
    func refreshSession(refreshToken: String) async -> Bool {
        print("AuthViewModel: refreshSession called.")
        let refreshInput = InitiateAuthInput(
            authFlow: .refreshTokenAuth, // REFRESH_TOKEN_AUTH フローを使用
            authParameters: ["REFRESH_TOKEN": refreshToken],
            clientId: self.clientId
        )
        do {
            print("AuthViewModel: Calling Cognito InitiateAuth with REFRESH_TOKEN...")
            let response = try await cognitoClient.initiateAuth(input: refreshInput)
            print("AuthViewModel: Cognito InitiateAuth (Refresh) response received.")

            if let authResult = response.authenticationResult,
               let newIdToken = authResult.idToken
            {
                print("AuthViewModel: New ID Token received from refresh.")
                if let claims = decode(jwtToken: newIdToken) {
                    print("AuthViewModel: New JWT decoded successfully.")
                    // 状態とUserDefaultsを更新
                    self.idToken = newIdToken
                    self.userSub = claims.sub
                    self.userEmail = claims.email
                    // リフレッシュトークン自体は通常変わらないが、もし新しいものが返ってきた場合のために更新する
                    // self.refreshToken = authResult.refreshToken ?? refreshToken
                    self.refreshToken = refreshToken // 今回は古いものを保持する
                    self.isSignedIn = true

                    UserDefaults.standard.set(newIdToken, forKey: idTokenKey)
                    UserDefaults.standard.set(claims.sub, forKey: userSubKey)
                    UserDefaults.standard.set(claims.email, forKey: userEmailKey)
                    UserDefaults.standard.set(self.refreshToken, forKey: refreshTokenKey) // 更新された可能性も考慮

                    print("AuthViewModel: Session refreshed successfully.")
                    return true
                } else {
                    print("AuthViewModel: Failed to decode refreshed JWT.")
                    return false
                }
            } else {
                print("AuthViewModel: Refreshed AuthenticationResult or ID Token was nil.")
                return false
            }
        } catch {
            // 一般的なエラーハンドリング
            print("AuthViewModel: refreshSession FAILED with error: \(error)")
            // 必要に応じてエラーの種類を特定し、ログアウトなどの処理を追加
            // 例: リフレッシュトークンが無効な場合のエラーコードをチェック
            // if (error as? AWSCognitoIdentityProviderError)?.isNotAuthorizedException == true { ... }
            return false
        }
    }

    /// 有効なIDトークンを取得する。必要であればセッションをリフレッシュする。
    /// API呼び出しの直前にこの関数を使うことを推奨。
    /// - Returns: 有効なIDトークン (String?)。取得失敗時は nil。
    func getValidIdToken() async -> String? {
        print("AuthViewModel: getValidIdToken called.")
        guard isSignedIn, let currentIdToken = self.idToken, let currentRefreshToken = self.refreshToken else {
            print("AuthViewModel: Not signed in or tokens missing.")
            return nil // サインインしていない、またはトークンがない
        }

        // 現在のIDトークンをデコードして有効期限を確認
        guard let claims = decode(jwtToken: currentIdToken) else {
            print("AuthViewModel: Failed to decode current ID token. Attempting refresh...")
            // デコード失敗時はリフレッシュを試みる
            let refreshed = await refreshSession(refreshToken: currentRefreshToken)
           
            return refreshed ? self.idToken : nil // リフレッシュ後のIDトークンを返す (失敗時はnil)
        }

        // 有効期限が近いか (例: 残り5分以内)
        let expirationDate = claims.exp
        let thresholdDate = Date().addingTimeInterval(5 * 60) // 5分前

        if expirationDate <= thresholdDate {
            // 有効期限が近い、または切れている場合はリフレッシュを試みる
            print("AuthViewModel: ID Token expired or expiring soon (\(expirationDate)). Refreshing session...")
            let refreshed = await refreshSession(refreshToken: currentRefreshToken)
            return refreshed ? self.idToken : nil // リフレッシュ後のIDトークンを返す (失敗時はnil)
        } else {
            // 有効期限が十分ある場合は現在のトークンを返す
            print("AuthViewModel: Current ID Token is valid until \(expirationDate).")
            return currentIdToken
        }
    }

    // --- ★★★ ここまでが自動更新機能 ★★★ ---

} // End AuthViewModel


// MARK: - JWT Helper Functions (変更なし)
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

func decode(jwtToken token: String) -> AuthClaims? {
     let segments = token.components(separatedBy: ".")
    guard segments.count > 1,
          let payloadData = base64UrlDecode(segments[1]),
          let json = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any]
    else {
        print("JWT decoding failed: Invalid segment count or payload data.")
        return nil
    }
    guard let sub = json["sub"] as? String,
          let email = json["email"] as? String,
          let expInt = json["exp"] as? TimeInterval
    else {
        print("Required JWT claims (sub, email, or exp) missing.")
        return nil
    }
    let expDate = Date(timeIntervalSince1970: expInt)
    let username = (json["cognito:username"] as? String) ?? "unknown"
    return AuthClaims(sub: sub, username: username, email: email, exp: expDate, rawClaims: json)
}
