import Foundation

// Represents a single item posted for trade or donation on LimbSwap.
struct Listing: Identifiable, Codable {
    var id: String
    var sellerId: String
    var sellerName: String
    var title: String
    var category: Category
    var size: String
    var side: Side           // Which side this item is for (Left or Right)
    var condition: Condition
    var tradeType: TradeType
    var description: String
    var imageURLs: [String]
    var imageBase64: String?   // primary image stored as base64
    var location: String
    var createdAt: Date
    var isActive: Bool

    // MARK: — Enums

    enum Category: String, Codable, CaseIterable {
        case shoe               = "Shoe"
        case glove              = "Glove"
        case sleeve             = "Sleeve"
        case prostheticAccessory = "Prosthetic Accessory"
        case clothing           = "Clothing"
        case other              = "Other"
    }

    enum Side: String, Codable, CaseIterable {
        case left  = "Left"
        case right = "Right"
    }

    enum Condition: String, Codable, CaseIterable {
        case new      = "New"
        case likeNew  = "Like New"
        case good     = "Good"
        case fair     = "Fair"
    }

    enum TradeType: String, Codable, CaseIterable {
        case free  = "Free"
        case trade = "Trade"
    }
}
