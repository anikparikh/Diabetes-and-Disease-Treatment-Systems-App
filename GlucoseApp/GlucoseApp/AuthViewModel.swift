import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var authError: String?

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        user = Auth.auth().currentUser
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    func signIn(email: String, password: String) {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            authError = "Please enter both email and password."
            return
        }

        isLoading = true
        authError = nil

        Auth.auth().signIn(withEmail: cleanedEmail, password: password) { [weak self] _, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                self.authError = error.localizedDescription
            }
        }
    }

    func createAccount(email: String, password: String, confirmPassword: String) {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            authError = "Email and password are required."
            return
        }

        guard password == confirmPassword else {
            authError = "Passwords do not match."
            return
        }

        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        authError = nil

        Auth.auth().createUser(withEmail: cleanedEmail, password: password) { [weak self] _, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                self.authError = error.localizedDescription
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            authError = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        authError = nil
    }

    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Unable to read Apple ID credentials."
                return
            }

            guard let nonce = currentNonce else {
                authError = "Invalid Apple sign-in state. Please try again."
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                authError = "Unable to fetch Apple identity token."
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                authError = "Unable to decode Apple identity token."
                return
            }

            isLoading = true
            authError = nil

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { [weak self] _, error in
                guard let self else { return }
                self.isLoading = false
                self.currentNonce = nil

                if let error {
                    self.authError = error.localizedDescription
                }
            }

        case .failure(let error):
            authError = error.localizedDescription
        }
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
