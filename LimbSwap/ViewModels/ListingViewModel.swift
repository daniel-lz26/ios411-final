import Combine
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

    /// Converts the first selected image to base64, creates the Listing struct,
    /// and writes it to Firestore. No Firebase Storage used.
    func postListing(seller: User) async {
        guard !title.isEmpty, !size.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }

        isLoading      = true
        errorMessage   = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let listingId = UUID().uuidString

            // Convert first selected image to base64 (one image per listing for Firestore size limit)
            var base64Image: String? = nil
            if let firstImage = selectedImages.first {
                base64Image = listingService.imageToBase64(firstImage)
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
                imageURLs:   [],          // empty — no Firebase Storage
                imageBase64: base64Image,
                location:    seller.location,
                createdAt:   Date(),
                isActive:    true
            )

            try await listingService.createListing(listing, imageBase64: base64Image)
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
