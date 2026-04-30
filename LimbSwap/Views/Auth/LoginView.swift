import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email    = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo / Branding
                VStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.limbGreen)
                    Text("LimbSwap")
                        .font(.largeTitle.bold())
                    Text("Trade single-sided clothing & shoes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Error
                    if let error = authVM.errorMessage {
                        ErrorBanner(message: error)
                    }

                    // Sign In button
                    Button {
                        Task { await authVM.signIn(email: email, password: password) }
                    } label: {
                        Group {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.limbGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)

                Spacer()

                // Navigate to Sign Up
                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .font(.subheadline)
                .foregroundColor(.limbGreen)
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authVM)
            }
        }
    }
}
