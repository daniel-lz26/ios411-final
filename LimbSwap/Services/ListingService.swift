import Foundation
import FirebaseFirestore
import UIKit

// Handles all Firestore operations for listings.
// Images are stored as base64 strings inside the Firestore document instead of
// Firebase Storage, which requires Google Cloud billing unavailable for this project.
class ListingService {
    static let shared = ListingService()
    private let db = Firestore.firestore()

    // MARK: — Fetch

    /// Loads all active listings for a given side (used by HomeViewModel for the filtered feed).
    func fetchListings(for side: Listing.Side) async throws -> [Listing] {
        let snapshot = try await db.collection(K.Firestore.listings)
            .whereField("side", isEqualTo: side.rawValue)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decode($0.data()) }
    }

    /// Loads all active listings regardless of side (used when user has .both affected sides).
    func fetchAllListings() async throws -> [Listing] {
        let snapshot = try await db.collection(K.Firestore.listings)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decode($0.data()) }
    }

    /// Fetches listings posted by a specific user (used in ProfileView).
    func fetchListings(by sellerId: String) async throws -> [Listing] {
        let snapshot = try await db.collection(K.Firestore.listings)
            .whereField("sellerId", isEqualTo: sellerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decode($0.data()) }
    }

    /// Full-text-style search: fetches all active listings, then filters client-side by keyword.
    func searchListings(query: String) async throws -> [Listing] {
        let all = try await fetchAllListings()
        guard !query.isEmpty else { return all }
        let lower = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lower) ||
            $0.description.lowercased().contains(lower) ||
            $0.category.rawValue.lowercased().contains(lower)
        }
    }

    // MARK: — Create

    /// Creates a new listing document in Firestore, embedding the image as base64 if provided.
    func createListing(_ listing: Listing, imageBase64: String?) async throws {
        var data: [String: Any] = [
            "id":          listing.id,
            "sellerId":    listing.sellerId,
            "sellerName":  listing.sellerName,
            "title":       listing.title,
            "category":    listing.category.rawValue,
            "size":        listing.size,
            "side":        listing.side.rawValue,
            "condition":   listing.condition.rawValue,
            "tradeType":   listing.tradeType.rawValue,
            "description": listing.description,
            "imageURLs":   listing.imageURLs,
            "location":    listing.location,
            "createdAt":   listing.createdAt,
            "isActive":    listing.isActive
        ]
        if let base64 = imageBase64 {
            data["imageBase64"] = base64
        }
        try await db.collection(K.Firestore.listings)
            .document(listing.id)
            .setData(data)
    }

    // MARK: — Image helper

    /// Compress and convert UIImage to base64 string for Firestore storage.
    /// Resizes to max 600px wide to keep the Firestore document under 1 MB.
    func imageToBase64(_ image: UIImage) -> String? {
        let maxWidth: CGFloat = 600
        let scale = maxWidth / image.size.width
        let newSize = image.size.width > maxWidth
            ? CGSize(width: maxWidth, height: image.size.height * scale)
            : image.size

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        // Compress to JPEG at 0.4 quality — keeps size well under Firestore 1 MB limit
        return resized.jpegData(compressionQuality: 0.4)?.base64EncodedString()
    }

    // MARK: — Decode helper

    /// Maps a raw Firestore data dictionary to a Listing struct.
    private func decode(_ data: [String: Any]) -> Listing? {
        guard
            let id          = data["id"]          as? String,
            let sellerId    = data["sellerId"]     as? String,
            let sellerName  = data["sellerName"]   as? String,
            let title       = data["title"]        as? String,
            let categoryRaw = data["category"]     as? String,
            let category    = Listing.Category(rawValue: categoryRaw),
            let size        = data["size"]         as? String,
            let sideRaw     = data["side"]         as? String,
            let side        = Listing.Side(rawValue: sideRaw),
            let condRaw     = data["condition"]    as? String,
            let condition   = Listing.Condition(rawValue: condRaw),
            let tradeRaw    = data["tradeType"]    as? String,
            let tradeType   = Listing.TradeType(rawValue: tradeRaw),
            let description = data["description"]  as? String,
            let location    = data["location"]     as? String,
            let isActive    = data["isActive"]     as? Bool
        else { return nil }

        let createdAt   = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let imageURLs   = data["imageURLs"]   as? [String] ?? []
        let imageBase64 = data["imageBase64"] as? String

        return Listing(
            id:          id,
            sellerId:    sellerId,
            sellerName:  sellerName,
            title:       title,
            category:    category,
            size:        size,
            side:        side,
            condition:   condition,
            tradeType:   tradeType,
            description: description,
            imageURLs:   imageURLs,
            imageBase64: imageBase64,
            location:    location,
            createdAt:   createdAt,
            isActive:    isActive
        )
    }
}
