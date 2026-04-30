import SwiftUI

// Shows the current user's profile and their posted listings.
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var myListings:  [Listing] = []
    @State private var isLoading   = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: — Profile header
                if let user = authVM.currentUser {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 16) {
                                // Avatar
                                Circle()
                                    .fill(Color.limbGreen.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Text(String(user.name.prefix(1)))
                                            .font(.title.bold())
                                            .foregroundColor(.limbGreen)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.title3.bold())
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Divider()

                            // Amputation profile chips
                            HStack(spacing: 8) {
                                TagChip(text: user.amputationType.rawValue, color: .limbGreen)
                                TagChip(text: "\(user.affectedSide.rawValue) side", color: .secondary)
                            }

                            Text(user.location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // MARK: — My Listings
                Section("My Listings") {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if myListings.isEmpty {
                        Text("You haven't posted anything yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(myListings) { listing in
                            NavigationLink(destination: ListingDetailView(listing: listing)) {
                                ListingRow(listing: listing)
                            }
                        }
                    }
                }

                // MARK: — Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await loadMyListings() }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { authVM.signOut() }
                Button("Cancel",  role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: — Load Listings

    private func loadMyListings() async {
        guard let userId = authVM.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        myListings = (try? await ListingService.shared.fetchListings(by: userId)) ?? []
    }
}
