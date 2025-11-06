import SwiftUI

// --- ★★★ Environment Key Setup (Top Level) ★★★ ---
// Define the key for accessing the binding in the environment
private struct ShowAuthenticationSheetKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false) // Default value is a non-binding false
}

// Extend EnvironmentValues to add a computed property for easy access
extension EnvironmentValues {
    var showAuthenticationSheet: Binding<Bool> {
        get { self[ShowAuthenticationSheetKey.self] }
        set { self[ShowAuthenticationSheetKey.self] = newValue }
    }
}
// --- ★★★ End Environment Key Setup ★★★ ---


// MARK: - ContentView

struct ContentView: View {
    // Access the shared ViewModels from the environment (will be injected by App)
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    // State to control the presentation of the authentication sheet
    @State private var showingAuthSheet = false
    // State to control the presentation of the nickname setting sheet
    @State private var showingSetNicknameSheet = false

    var body: some View {
        MainTabView()
            // --- Authentication Sheet ---
            .sheet(isPresented: $showingAuthSheet) {
                // Pass the binding and environment objects to the sheet
                AuthenticationSheetView(showingSheet: $showingAuthSheet)
                    .environmentObject(authViewModel) // Pass AuthViewModel
            }
            // --- Nickname Setting Sheet ---
            .sheet(isPresented: $showingSetNicknameSheet) {
                // Pass the binding and environment objects to the sheet
                SetNicknameView() // The view for setting nickname
                    .environmentObject(authViewModel) // Pass AuthViewModel
                    .environmentObject(profileViewModel) // Pass ProfileViewModel
            }
            // --- Observe sign-in status changes ---
            .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    // Close auth sheet on successful sign-in
                    showingAuthSheet = false
                    // Check if nickname needs setting
                    Task {
                        await checkNicknameAndShowSheetIfNeeded()
                    }
                    // ★★★ 追加: ログイン時にブックマーク取得をトリガー ★★★
                    profileViewModel.handleSignIn()
                } else {
                    // Close nickname sheet on sign-out (just in case)
                    showingSetNicknameSheet = false
                    // ★★★ 追加: ログアウト時にブックマークをクリア ★★★
                    profileViewModel.handleSignOut()
                }
            }
            // --- Make the auth sheet binding available to child views ---
            .environment(\.showAuthenticationSheet, $showingAuthSheet)
            // --- Initial nickname check on app launch (if already signed in) ---
            .task {
                 if authViewModel.isSignedIn {
                     await checkNicknameAndShowSheetIfNeeded()
                     // ★★★ 追加: アプリ起動時(ログイン済みなら)にもブックマーク取得 ★★★
                     profileViewModel.handleSignIn()
                 }
            }
    }

    /// Checks if the current user's nickname is set and shows the SetNicknameView if not.
    private func checkNicknameAndShowSheetIfNeeded() async {
        guard let userId = authViewModel.userSub else {
            return // Need user info
        }

        // Fetch the latest nickname from the server (also updates cache)
        // ★★★ 修正: idToken 引数を削除 ★★★ (適用済み)
        _ = await profileViewModel.fetchNickname(userId: userId)

        // Check the cached nickname
        let currentNickname = profileViewModel.userNicknames[userId]

        // Show sheet if nickname is nil (never fetched) or empty
        if currentNickname == nil || currentNickname?.isEmpty == true {
            showingSetNicknameSheet = true
        }
    }
}


// MARK: - AuthenticationSheetView (変更なし)

struct AuthenticationSheetView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    // Binding to control the sheet presentation (passed from ContentView)
    @Binding var showingSheet: Bool

    // State for email, password, etc.
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingConfirmationView = false
    @State private var isSignUpMode = false // To toggle between Sign In/Sign Up

    var body: some View {
        // Needs NavigationStack for the confirmation view destination
        NavigationStack {
            VStack(spacing: 20) {
                Text(isSignUpMode ? "新規登録" : "ログイン")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled() // Disable autocorrect for email

                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)

                if isSignUpMode {
                    // Sign Up Button
                    Button {
                        Task {
                            let success = await authViewModel.signUp(email: email, password: password)
                            if success {
                                // Navigate to confirmation view on success
                                isShowingConfirmationView = true
                            } else {
                                // TODO: Show error alert to user
                                print("Sign up failed (show alert)")
                            }
                        }
                    } label: {
                        Text("登録して確認コード入力へ")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange) // Use orange for sign up

                    // Toggle to Sign In mode
                    Button("またはログイン") { isSignUpMode = false }

                } else {
                    // Sign In Button
                    Button {
                        Task {
                            // No need to check success here, AuthViewModel handles state
                            await authViewModel.signIn(email: email, password: password)
                            // `onChange` in ContentView will close the sheet on success
                        }
                    } label: {
                        Text("ログイン")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent) // Default tint (blue) for sign in

                    // Toggle to Sign Up mode
                    Button("新規登録はこちら") { isSignUpMode = true }
                }
                Spacer() // Pushes content to the top
            }
            .padding()
            // Navigate to ConfirmationView when isShowingConfirmationView is true
            .navigationDestination(isPresented: $isShowingConfirmationView) {
                // Pass the necessary data and binding
                ConfirmationView(showingAuthSheet: $showingSheet, email: email)
                    .environmentObject(authViewModel) // Pass AuthViewModel
            }
            .toolbar {
                // Add a Cancel button to dismiss the sheet
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { showingSheet = false }
                }
            }
        } // End NavigationStack
    } // End body
} // End struct AuthenticationSheetView

