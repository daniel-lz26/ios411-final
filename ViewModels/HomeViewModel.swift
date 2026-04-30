import Foundation

// Loads the filtered listing feed for the home screen.
@MainActor
class HomeViewModel: ObservableObject {
    @Published var listings:     [Listing] = []
    @Published var isLoading     = false
    @Published var errorMessage: String?

    private let service = ListingService.shared

    /// Fetches listings filtered to show the *opposite* side from the user's affected side.
    /// If the user has .both sides affected, all listings are returned instead.
    func loadFeed(for user: User) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch user.affectedSide {
            case .left:
                // Left amputee needs right-side items.
                listings = try await service.fetchListings(for: .right)
            case .right:
                // Right amputee needs left-side items.
                listings = try await service.fetchListings(for: .left)
            case .both:
                // Both sides affected — show everything.
                listings = try await service.fetchAllListings()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
