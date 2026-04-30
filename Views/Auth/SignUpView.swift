import SwiftUI

// Collects the user's basic info plus their amputation profile.
// The amputation profile powers the home feed auto-filter — the app's core feature.
struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name            = ""
    @State private var email           = ""
    @State private var password        = ""
    @State private var location        = ""
    @State private var amputationType  = User.AmputationType.belowKnee
    @State private var affectedSide    = User.Side.left

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Your Account")
                    .font(.title2.bold())
                    .padding(.top)

                // Basic info section
                GroupBox("Your Info") {
                    VStack(spacing: 12) {
                        field("Name",     text: $name,     type: .name)
                        field("Email",    text: $email,    type: .emailAddress)
                        field("City, State", text: $location, type: .addressCity)
                        SecureField("Password (6+ characters)", text: $password)
                            .textContentType(.newPassword)
                            .fieldStyle()
                    }
                }

                // Amputation profile section — drives the smart feed filter
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amputation Profile")
                            .font(.headline)
                        Text("We use this to show you listings for the opposite side — so a left-side amputee sees right-side items.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Type", selection: $amputationType) {
                            ForEach(User.AmputationType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("Affected Side", selection: $affectedSide) {
                            ForEach(User.Side.allCases, id: \.self) { side in
                                Text(side.rawValue).tag(side)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Error
                if let error = authVM.errorMessage {
                    ErrorBanner(message: error)
                }

                // Submit
                Button {
                    Task {
                        await authVM.signUp(
                            name:           name,
                            email:          email,
                            password:       password,
                            location:       location,
                            amputationType: amputationType,
                            affectedSide:   affectedSide
                        )
                    }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(formIsValid ? Color.limbGreen : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!formIsValid || authVM.isLoading)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Helpers

    private var formIsValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6 && !location.isEmpty
    }

    private func field(_ label: String, text: Binding<String>, type: UITextContentType) -> some View {
        TextField(label, text: text)
            .textContentType(type)
            .keyboardType(type == .emailAddress ? .emailAddress : .default)
            .autocapitalization(type == .emailAddress ? .none : .words)
            .fieldStyle()
    }
}

// Shared modifier so every text field has the same look.
private extension View {
    func fieldStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}
