import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Grow Your Glucose")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
                    .padding(.top, 50)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: handleLogin) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(authViewModel.isLoading)

                SignInWithAppleButton(.signIn, onRequest: authViewModel.prepareAppleSignInRequest, onCompletion: authViewModel.handleAppleSignInResult)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .disabled(authViewModel.isLoading)

                if let errorMessage = authViewModel.authError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()

                NavigationLink(destination: SignupView().environmentObject(authViewModel)) {
                    Text("Don't have an account? Sign up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    func handleLogin() {
        authViewModel.signIn(email: email, password: password)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
