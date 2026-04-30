import Foundation
import FirebaseFirestore

// Handles all Firestore operations for conversations and chat messages.
class MessageService {
    static let shared = MessageService()
    private let db = Firestore.firestore()

    // Holds the active Firestore snapshot listener so we can detach it when needed.
    private var messageListener: ListenerRegistration?

    // MARK: — Conversations

    /// Fetches all conversations where the current user is a participant.
    func fetchConversations(for userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection(K.Firestore.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decodeConversation($0.data()) }
    }

    /// Creates a new conversation document or returns the existing one if it already exists.
    /// Returns the conversation ID.
    func getOrCreateConversation(
        currentUserId: String,
        currentUserName: String,
        otherUserId: String,
        otherUserName: String,
        listing: Listing
    ) async throws -> String {
        // Check if a conversation for this listing already exists between these two users.
        let snapshot = try await db.collection(K.Firestore.conversations)
            .whereField("listingId", isEqualTo: listing.id)
            .whereField("participantIds", arrayContains: currentUserId)
            .getDocuments()

        if let existing = snapshot.documents.first {
            return existing.documentID
        }

        // No existing conversation — create one.
        let convId = UUID().uuidString
        let data: [String: Any] = [
            "id":               convId,
            "participantIds":   [currentUserId, otherUserId],
            "listingId":        listing.id,
            "listingTitle":     listing.title,
            "lastMessage":      "",
            "lastMessageDate":  Date(),
            "otherUserName":    otherUserName,
            "otherUserImageURL": ""
        ]
        try await db.collection(K.Firestore.conversations).document(convId).setData(data)
        return convId
    }

    // MARK: — Messages

    /// Sends a text message and updates the conversation's lastMessage field.
    func sendMessage(text: String, conversationId: String, senderId: String) async throws {
        let msgId = UUID().uuidString
        let now   = Date()

        // Write the message to the subcollection.
        let msgData: [String: Any] = [
            "id":             msgId,
            "conversationId": conversationId,
            "senderId":       senderId,
            "text":           text,
            "timestamp":      now
        ]
        try await db
            .collection(K.Firestore.conversations)
            .document(conversationId)
            .collection(K.Firestore.messages)
            .document(msgId)
            .setData(msgData)

        // Update the parent conversation's preview fields.
        try await db
            .collection(K.Firestore.conversations)
            .document(conversationId)
            .updateData([
                "lastMessage":     text,
                "lastMessageDate": now
            ])
    }

    /// Attaches a real-time Firestore listener for messages in a conversation.
    /// The `onChange` closure is called every time a new message arrives.
    func listenForMessages(
        conversationId: String,
        onChange: @escaping ([Message]) -> Void
    ) {
        // Detach any previous listener first.
        messageListener?.remove()

        messageListener = db
            .collection(K.Firestore.conversations)
            .document(conversationId)
            .collection(K.Firestore.messages)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let messages = docs.compactMap { self.decodeMessage($0.data()) }
                onChange(messages)
            }
    }

    /// Stops the active message listener. Call this when leaving the chat screen.
    func stopListening() {
        messageListener?.remove()
        messageListener = nil
    }

    // MARK: — Decode helpers

    private func decodeConversation(_ data: [String: Any]) -> Conversation? {
        guard
            let id              = data["id"]              as? String,
            let participantIds  = data["participantIds"]  as? [String],
            let listingId       = data["listingId"]       as? String,
            let listingTitle    = data["listingTitle"]    as? String,
            let lastMessage     = data["lastMessage"]     as? String,
            let otherUserName   = data["otherUserName"]   as? String
        else { return nil }

        let lastMessageDate = (data["lastMessageDate"] as? Timestamp)?.dateValue() ?? Date()

        return Conversation(
            id: id,
            participantIds: participantIds,
            listingId: listingId,
            listingTitle: listingTitle,
            lastMessage: lastMessage,
            lastMessageDate: lastMessageDate,
            otherUserName: otherUserName,
            otherUserImageURL: data["otherUserImageURL"] as? String
        )
    }

    private func decodeMessage(_ data: [String: Any]) -> Message? {
        guard
            let id             = data["id"]             as? String,
            let conversationId = data["conversationId"] as? String,
            let senderId       = data["senderId"]       as? String,
            let text           = data["text"]           as? String
        else { return nil }

        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

        return Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            timestamp: timestamp
        )
    }
}
