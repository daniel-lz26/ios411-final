import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

// Handles all Firestore + Firebase Storage operations for listings.
class ListingService {
    static let shared = ListingService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

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

    /// Creates a new listing document in Firestore and returns it.
    func createListing(_ listing: Listing) async throws {
        let data: [String: Any] = [
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
        try await db.collection(K.Firestore.listings)
            .document(listing.id)
            .setData(data)
    }

    // MARK: — Image Upload

    /// Uploads a UIImage to Firebase Storage and returns the download URL string.
    func uploadImage(_ image: UIImage, listingId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "LimbSwap", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
        }
        let ref = storage.reference()
            .child("listings/\(listingId)/\(UUID().uuidString).jpg")
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: — Decode helper

    /// Maps a raw Firestore data dictionary to a Listing struct.
    private func decode(_ data: [String: Any]) -> Listing? {
        guard
            let id          = data["id"]          as? String,
            let sellerId    = data["sellerId"]    as? String,
            let sellerName  = data["sellerName"]  as? String,
            let title       = data["title"]       as? String,
            let categoryRaw = data["category"]    as? String,
            let category    = Listing.Category(rawValue: categoryRaw),
            let size        = data["size"]        as? String,
            let sideRaw     = data["side"]        as? String,
            let side        = Listing.Side(rawValue: sideRaw),
            let condRaw     = data["condition"]   as? String,
            let condition   = Listing.Condition(rawValue: condRaw),
            let tradeRaw    = data["tradeType"]   as? String,
            let tradeType   = Listing.TradeType(rawValue: tradeRaw),
            let description = data["description"] as? String,
            let imageURLs   = data["imageURLs"]   as? [String],
            let location    = data["location"]    as? String,
            let isActive    = data["isActive"]    as? Bool
        else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Listing(
            id: id,
            sellerId: sellerId,
            sellerName: sellerName,
            title: title,
            category: category,
            size: size,
            side: side,
            condition: condition,
            tradeType: tradeType,
            description: description,
            imageURLs: imageURLs,
            location: location,
            createdAt: createdAt,
            isActive: isActive
        )
    }
}
