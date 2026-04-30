import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func signUp(email: String, password: String, name: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func saveUserProfile(_ user: User) async throws {
        let data: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "location": user.location,
            "amputationType": user.amputationType.rawValue,
            "affectedSide": user.affectedSide.rawValue,
            "createdAt": user.createdAt
        ]
        try await db.collection(K.Firestore.users).document(user.id).setData(data)
    }
    
    func fetchUser(id: String) async throws -> User? {
        let doc = try await db.collection(K.Firestore.users).document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return User(
            id: data["id"] as? String ?? "",
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            location: data["location"] as? String ?? "",
            amputationType: User.AmputationType(rawValue: data["amputationType"] as? String ?? "") ?? .belowKnee,
            affectedSide: User.Side(rawValue: data["affectedSide"] as? String ?? "") ?? .left,
            profileImageURL: data["profileImageURL"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}