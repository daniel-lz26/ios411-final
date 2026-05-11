import Foundation
import FirebaseFirestore
import FirebaseAuth

// SeedData.swift
// Run seedDatabase() once from the app — comment it out after first run.
// Call from LimbSwapApp.swift init() during development only.
//
// Test accounts seeded here:
//   Email: user1@limbswap.com  Password: Test1234!
//   Email: user2@limbswap.com  Password: Test1234!

struct SeedData {

    static let db = Firestore.firestore()

    static func seedDatabase() async {
        do {
            let userIds = try await seedUsers()
            try await seedListings(userIds: userIds)
            try await seedConversations(userIds: userIds)
            print("Seed data loaded successfully")
        } catch {
            print("Seed error: \(error)")
        }
    }

    // MARK: - Seed Users

    static func seedUsers() async throws -> [String: String] {
        let users: [(email: String, password: String, name: String,
                     location: String, amputationType: String, affectedSide: String)] = [
            (
                email: "user1@limbswap.com",
                password: "Test1234!",
                name: "Marcus T.",
                location: "Los Angeles, CA",
                amputationType: "Below Knee",
                affectedSide: "Left"
            ),
            (
                email: "user2@limbswap.com",
                password: "Test1234!",
                name: "Sarah K.",
                location: "San Diego, CA",
                amputationType: "Below Elbow",
                affectedSide: "Right"
            ),
        ]

        var ids: [String: String] = [:]

        for entry in users {
            // Create Firebase Auth account (ignore error if already exists)
            let result = try? await Auth.auth().createUser(
                withEmail: entry.email,
                password: entry.password
            )

            // Use the real Firebase UID if created, otherwise fall back to email-based key
            let uid = result?.user.uid ?? entry.email.replacingOccurrences(of: "@", with: "_")
                                                      .replacingOccurrences(of: ".", with: "_")

            let data: [String: Any] = [
                "id":            uid,
                "name":          entry.name,
                "email":         entry.email,
                "location":      entry.location,
                "amputationType": entry.amputationType,
                "affectedSide":  entry.affectedSide,
                "createdAt":     Date()
            ]
            try await db.collection("users").document(uid).setData(data)
            ids[entry.email] = uid
        }

        return ids
    }

    // MARK: - Seed Listings

    static func seedListings(userIds: [String: String]) async throws {
        let items: [(title: String, category: String, size: String,
                     side: String, condition: String,
                     tradeType: String, description: String,
                     location: String, sellerName: String)] = [
            (
                title: "Nike Air Max 97 Right Shoe",
                category: "Shoe",
                size: "10",
                side: "Right",
                condition: "Like New",
                tradeType: "Free",
                description: "Barely worn. Left below-knee amputee — only ever wore the right shoe. Perfect condition, no scuffs. Happy to ship anywhere.",
                location: "Los Angeles, CA",
                sellerName: "Marcus T."
            ),
            (
                title: "Adidas Ultraboost Left Shoe",
                category: "Shoe",
                size: "9",
                side: "Left",
                condition: "Good",
                tradeType: "Trade",
                description: "Right side amputee here. Great running shoe, worn about 10 times. Looking to trade for a right shoe same size if possible.",
                location: "San Diego, CA",
                sellerName: "Sarah K."
            ),
            (
                title: "Work Glove Right Hand, Size L",
                category: "Glove",
                size: "L",
                side: "Right",
                condition: "New",
                tradeType: "Free",
                description: "Brand new pair, only using the left glove. Leather work glove, size large. Free to whoever needs it.",
                location: "Irvine, CA",
                sellerName: "James R."
            ),
            (
                title: "Left Hand Golf Glove",
                category: "Glove",
                size: "M",
                side: "Left",
                condition: "Good",
                tradeType: "Free",
                description: "FootJoy golf glove, left hand, medium. Right hand amputee — this has been sitting in my drawer for a year. Someone make use of it!",
                location: "Anaheim, CA",
                sellerName: "Chris M."
            ),
            (
                title: "New Balance 990 Right Shoe",
                category: "Shoe",
                size: "11",
                side: "Right",
                condition: "Like New",
                tradeType: "Free",
                description: "Classic New Balance, right shoe only. Worn twice. Left side amputee. Size 11 wide. Great everyday shoe.",
                location: "Long Beach, CA",
                sellerName: "David P."
            ),
            (
                title: "Compression Sleeve Left Arm",
                category: "Sleeve",
                size: "S",
                side: "Left",
                condition: "New",
                tradeType: "Free",
                description: "Medical compression sleeve, left arm, small. Never worn — bought the wrong side. Free, just cover shipping if needed.",
                location: "Riverside, CA",
                sellerName: "Linda H."
            ),
            (
                title: "Hiking Boot Right Foot",
                category: "Shoe",
                size: "10.5",
                side: "Right",
                condition: "Good",
                tradeType: "Trade",
                description: "Merrell Moab hiking boot, right foot, size 10.5. Used one season. Left below-knee amputee — looking to trade for a left boot same size ideally.",
                location: "Pasadena, CA",
                sellerName: "Tom W."
            ),
            (
                title: "Dress Shoe Left Foot Size 9",
                category: "Shoe",
                size: "9",
                side: "Left",
                condition: "Like New",
                tradeType: "Free",
                description: "Oxford dress shoe, black leather, left foot size 9. Right side amputee. Wore it to one wedding. Ridiculous to let it go to waste.",
                location: "Burbank, CA",
                sellerName: "Kevin O."
            ),
        ]

        let user1Id = userIds["user1@limbswap.com"] ?? "seed_user_1"
        let user2Id = userIds["user2@limbswap.com"] ?? "seed_user_2"
        let sellerIds = [user1Id, user2Id]

        for (index, item) in items.enumerated() {
            let id = "seed_listing_\(index + 1)"

            // Stagger creation dates over past 2 weeks so the feed looks natural
            let daysAgo = Double(items.count - index) * 1.5
            let createdAt = Date().addingTimeInterval(-daysAgo * 86400)

            let data: [String: Any] = [
                "id":          id,
                "sellerId":    sellerIds[index % 2],
                "sellerName":  item.sellerName,
                "title":       item.title,
                "category":    item.category,
                "size":        item.size,
                "side":        item.side,
                "condition":   item.condition,
                "tradeType":   item.tradeType,
                "description": item.description,
                "imageURLs":   [String](),
                "location":    item.location,
                "createdAt":   createdAt,
                "isActive":    true
            ]

            try await db.collection("listings").document(id).setData(data)
        }
    }

    // MARK: - Seed Conversations

    static func seedConversations(userIds: [String: String]) async throws {
        let user1Id   = userIds["user1@limbswap.com"] ?? "seed_user_1"
        let user2Id   = userIds["user2@limbswap.com"] ?? "seed_user_2"
        let user1Name = "Marcus T."
        let user2Name = "Sarah K."

        // Conversation 1: user1 messaged user2 about the Adidas Left Shoe (listing 2)
        let conv1Id = "seed_conv_1"
        let conv1Data: [String: Any] = [
            "id":              conv1Id,
            "participantIds":  [user1Id, user2Id],
            "listingId":       "seed_listing_2",
            "listingTitle":    "Adidas Ultraboost Left Shoe",
            "lastMessage":     "That works for me! I can do Saturday.",
            "lastMessageDate": Date().addingTimeInterval(-3600),
            "otherUserName":   user2Name,
            "otherUserImageURL": ""
        ]
        try await db.collection("conversations").document(conv1Id).setData(conv1Data)

        let conv1Messages: [(id: String, senderId: String, text: String, hoursAgo: Double)] = [
            ("seed_msg_1_1", user1Id, "Hey! Is the Adidas left shoe still available?", 5),
            ("seed_msg_1_2", user2Id, "Yes it is! Barely worn. Are you in the San Diego area?", 4.5),
            ("seed_msg_1_3", user1Id, "I'm in LA but I can meet halfway or shipping works too.", 4),
            ("seed_msg_1_4", user2Id, "Shipping is fine. Want to meet up this weekend instead?", 2),
            ("seed_msg_1_5", user1Id, "That works for me! I can do Saturday.", 1),
        ]
        for msg in conv1Messages {
            let msgData: [String: Any] = [
                "id":             msg.id,
                "conversationId": conv1Id,
                "senderId":       msg.senderId,
                "text":           msg.text,
                "timestamp":      Date().addingTimeInterval(-msg.hoursAgo * 3600)
            ]
            try await db.collection("conversations").document(conv1Id)
                .collection("messages").document(msg.id).setData(msgData)
        }

        // Conversation 2: user2 messaged user1 about the Nike Right Shoe (listing 1)
        let conv2Id = "seed_conv_2"
        let conv2Data: [String: Any] = [
            "id":              conv2Id,
            "participantIds":  [user2Id, user1Id],
            "listingId":       "seed_listing_1",
            "listingTitle":    "Nike Air Max 97 Right Shoe",
            "lastMessage":     "Size 10. Let me know if you want it!",
            "lastMessageDate": Date().addingTimeInterval(-7200),
            "otherUserName":   user2Name,
            "otherUserImageURL": ""
        ]
        try await db.collection("conversations").document(conv2Id).setData(conv2Data)

        let conv2Messages: [(id: String, senderId: String, text: String, hoursAgo: Double)] = [
            ("seed_msg_2_1", user2Id, "Hi! Do you still have the Nike Air Max listing?", 6),
            ("seed_msg_2_2", user1Id, "Yes, right shoe only. Perfect condition.", 5.5),
            ("seed_msg_2_3", user2Id, "What size is it exactly?", 5),
            ("seed_msg_2_4", user1Id, "Size 10. Let me know if you want it!", 2),
        ]
        for msg in conv2Messages {
            let msgData: [String: Any] = [
                "id":             msg.id,
                "conversationId": conv2Id,
                "senderId":       msg.senderId,
                "text":           msg.text,
                "timestamp":      Date().addingTimeInterval(-msg.hoursAgo * 3600)
            ]
            try await db.collection("conversations").document(conv2Id)
                .collection("messages").document(msg.id).setData(msgData)
        }
    }
}
