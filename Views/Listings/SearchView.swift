import SwiftUI

// The Search tab — lets users search and filter all active listings.
struct SearchView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var query           = ""
    @State private var results:  [Listing] = []
    @State private var isLoading       = false
    @State private var hasSearched     = false
    @State private var selectedCategory: Listing.Category? = nil
    @State private var selectedSide:     Listing.Side?     = nil

    private let service = ListingService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                Divider()

                // Results
                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if hasSearched && results.isEmpty {
                    emptyState
                } else {
                    List(filteredResults) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing)) {
                            ListingRow(listing: listing)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search listings…")
            .onSubmit(of: .search) {
                Task { await runSearch() }
            }
            .onChange(of: query) { newValue in
                if newValue.isEmpty {
                    results     = []
                    hasSearched = false
                }
            }
        }
    }

    // MARK: — Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filters
                ForEach(Listing.Category.allCases, id: \.self) { cat in
                    FilterChip(
                        title: cat.rawValue,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }

                Divider().frame(height: 20)

                // Side filters
                ForEach(Listing.Side.allCases, id: \.self) { side in
                    FilterChip(
                        title: "\(side.rawValue) side",
                        isSelected: selectedSide == side
                    ) {
                        selectedSide = selectedSide == side ? nil : side
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: — Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No results for "\(query)"")
                .font(.headline)
            Text("Try a different keyword or adjust the filters.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: — Client-side Filtering

    /// Applies selected category and side filters on top of the search results.
    private var filteredResults: [Listing] {
        results.filter { listing in
            let categoryMatch = selectedCategory == nil || listing.category == selectedCategory
            let sideMatch     = selectedSide     == nil || listing.side     == selectedSide
            return categoryMatch && sideMatch
        }
    }

    // MARK: — Search

    private func runSearch() async {
        isLoading   = true
        hasSearched = true
        defer { isLoading = false }
        results = (try? await service.searchListings(query: query)) ?? []
    }
}
