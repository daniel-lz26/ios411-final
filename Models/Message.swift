import Foundation

// A single chat message within a conversation.
struct Message: Identifiable, Codable {
    var id: String
    var conversationId: String
    var senderId: String
    var text: String
    var timestamp: Date
}

// A conversation thread between two users about a specific listing.
struct Conversation: Identifiable, Codable {
    var id: String
    var participantIds: [String]
    var listingId: String
    var listingTitle: String
    var lastMessage: String
    var lastMessageDate: Date
    var otherUserName: String
    var otherUserImageURL: String?
}
