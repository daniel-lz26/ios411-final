import Foundation
import UIKit

// Manages state for the Create Listing form and handles posting a new listing.
@MainActor
class ListingViewModel: ObservableObject {
    // MARK: — Form fields
    @Published var title        = ""
    @Published var category     = Listing.Category.shoe
    @Published var size         = ""
    @Published var side         = Listing.Side.left
    @Published var condition    = Listing.Condition.good
    @Published var tradeType    = Listing.TradeType.free
    @Published var description  = ""
    @Published var location     = ""
    @Published var selectedImages: [UIImage] = []

    // MARK: — State
    @Published var isLoading      = false
    @Published var errorMessage:  String?
    @Published var successMessage: String?  // Non-nil after a successful post

    private let listingService = ListingService.shared

    // MARK: — Post Listing

    /// Uploads images (if any), creates the Listing struct, and writes it to Firestore.
    func postListing(seller: User) async {
        isLoading      = true
        errorMessage   = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let listingId = UUID().uuidString
            var imageURLs: [String] = []

            // Upload each selected photo to Firebase Storage.
            for image in selectedImages {
                let url = try await listingService.uploadImage(image, listingId: listingId)
                imageURLs.append(url)
            }

            let listing = Listing(
                id:          listingId,
                sellerId:    seller.id,
                sellerName:  seller.name,
                title:       title,
                category:    category,
                size:        size,
                side:        side,
                condition:   condition,
                tradeType:   tradeType,
                description: description,
                imageURLs:   imageURLs,
                location:    seller.location,
                createdAt:   Date(),
                isActive:    true
            )

            try await listingService.createListing(listing)
            successMessage = "Your listing has been posted!"
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: — Reset

    /// Clears all form fields back to their default values.
    func resetForm() {
        title          = ""
        category       = .shoe
        size           = ""
        side           = .left
        condition      = .good
        tradeType      = .free
        description    = ""
        location       = ""
        selectedImages = []
    }
}
