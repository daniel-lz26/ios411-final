import Foundation

// Manages the conversations list and the active chat session.
@MainActor
class MessageViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages:      [Message]      = []
    @Published var isLoading      = false
    @Published var errorMessage:  String?
    @Published var messageText    = ""

    private let service = MessageService.shared

    // MARK: — Conversations

    /// Loads all conversations for the signed-in user.
    func loadConversations(for userId: String) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            conversations = try await service.fetchConversations(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Chat

    /// Starts listening for real-time messages in the given conversation.
    func listenForMessages(conversationId: String) {
        service.listenForMessages(conversationId: conversationId) { [weak self] msgs in
            Task { @MainActor in
                self?.messages = msgs
            }
        }
    }

    /// Sends the current messageText and clears the input field.
    func sendMessage(conversationId: String, senderId: String) async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""

        do {
            try await service.sendMessage(
                text:           text,
                conversationId: conversationId,
                senderId:       senderId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates or retrieves the conversation when a buyer taps "Message Seller".
    func getOrCreateConversation(
        currentUserId:   String,
        currentUserName: String,
        otherUserId:     String,
        otherUserName:   String,
        listing:         Listing
    ) async throws -> String {
        return try await service.getOrCreateConversation(
            currentUserId:   currentUserId,
            currentUserName: currentUserName,
            otherUserId:     otherUserId,
            otherUserName:   otherUserName,
            listing:         listing
        )
    }

    /// Stops the Firestore listener. Call when leaving the chat screen.
    func stopListening() {
        service.stopListening()
    }
}
