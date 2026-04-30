import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = HomeViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading listings...")
                } else if vm.listings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No listings yet")
                            .font(.headline)
                        Text("Check back soon or be the first to post!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(vm.listings) { listing in
                                NavigationLink(destination: ListingDetailView(listing: listing)) {
                                    ListingCard(listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("For You")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let user = authVM.currentUser {
                        // When both sides are affected we show all listings,
                        // otherwise we show the opposite side from what the user needs.
                        let label: String = {
                            switch user.affectedSide {
                            case .left:  return "Showing right-side items"
                            case .right: return "Showing left-side items"
                            case .both:  return "Showing all items"
                            }
                        }()
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                if let user = authVM.currentUser {
                    await vm.loadFeed(for: user)
                }
            }
        }
    }
}

struct ListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image placeholder / async image
            AsyncImage(url: URL(string: listing.imageURLs.first ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(height: 160)
            .clipped()
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                
                HStack {
                    Text(listing.side.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                    
                    Text(listing.tradeType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(listing.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}