//
//  SignupView.swift
//  GlucoseApp
//
//  Created by Sai Varsha Ravisankar on 11/3/25.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle.bold())
                .foregroundColor(.green)
                .padding(.top, 40)
                .onAppear { authViewModel.authError = nil }

            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .onChange(of: email) { _ in authViewModel.authError = nil }

            Group {
                if showPassword {
                    TextField("Password", text: $password)
                    TextField("Confirm Password", text: $confirmPassword)
                } else {
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Button(action: { showPassword.toggle() }) {
                Label(showPassword ? "Hide Passwords" : "Show Passwords", systemImage: showPassword ? "eye.slash" : "eye")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Button(action: handleSignup) {
                if authViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(authViewModel.isLoading)

            if let errorMessage = authViewModel.authError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .onChange(of: authViewModel.user) { user in
            if user != nil {
                dismiss()
            }
        }
    }

    func handleSignup() {
        authViewModel.createAccount(email: email, password: password, confirmPassword: confirmPassword)
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthViewModel())
}
