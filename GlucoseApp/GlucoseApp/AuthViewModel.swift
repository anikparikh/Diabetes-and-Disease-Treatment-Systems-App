import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var authError: String?

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

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
}
