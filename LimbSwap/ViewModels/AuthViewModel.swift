import Combine
import Foundation
import FirebaseAuth

// Manages authentication state and the signed-in user's profile.
// @MainActor ensures all @Published updates happen on the main thread.
@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?          // nil when signed out
    @Published var isLoading  = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    init() {
        // If Firebase already has a session (e.g. app relaunch), reload the profile.
        if let uid = authService.currentUserId {
            Task { await loadUser(id: uid) }
        }
    }

    // MARK: — Sign Up

    /// Creates a Firebase Auth account and saves the user profile to Firestore.
    func signUp(
        name: String,
        email: String,
        password: String,
        location: String,
        amputationType: User.AmputationType,
        affectedSide: User.Side
    ) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let uid = try await authService.signUp(email: email, password: password, name: name)
            let user = User(
                id:             uid,
                name:           name,
                email:          email,
                location:       location,
                amputationType: amputationType,
                affectedSide:   affectedSide,
                profileImageURL: nil,
                createdAt:      Date()
            )
            try await authService.saveUserProfile(user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Sign In

    /// Signs in with email and password, then fetches the user profile.
    func signIn(email: String, password: String) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            if let uid = authService.currentUserId {
                await loadUser(id: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Sign Out

    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Helpers

    private func loadUser(id: String) async {
        do {
            currentUser = try await authService.fetchUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
