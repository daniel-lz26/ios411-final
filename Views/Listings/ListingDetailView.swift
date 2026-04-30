import SwiftUI

// Full-detail view for a single listing. Lets a buyer start a conversation.
struct ListingDetailView: View {
    let listing: Listing
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var msgVM = MessageViewModel()

    // Controls navigation into the chat screen after a conversation is created.
    @State private var conversationId: String?
    @State private var showChat       = false
    @State private var isContacting   = false
    @State private var errorMessage:  String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Image carousel
                if listing.imageURLs.isEmpty {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 280)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.secondary))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(listing.imageURLs, id: \.self) { url in
                                AsyncImage(url: URL(string: url)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: UIScreen.main.bounds.width, height: 280)
                                .clipped()
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {

                    // Title + badges
                    Text(listing.title)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        TagChip(text: listing.side.rawValue,      color: .limbGreen)
                        TagChip(text: listing.condition.rawValue, color: .secondary)
                        TagChip(text: listing.tradeType.rawValue, color: listing.tradeType == .free ? .limbGreen : .orange)
                    }

                    Divider()

                    // Details grid
                    detailRow(label: "Category", value: listing.category.rawValue)
                    detailRow(label: "Size",     value: listing.size)
                    detailRow(label: "Location", value: listing.location)
                    detailRow(label: "Seller",   value: listing.sellerName)

                    Divider()

                    // Description
                    Text("Description")
                        .font(.headline)
                    Text(listing.description.isEmpty ? "No description provided." : listing.description)
                        .font(.body)
                        .foregroundColor(listing.description.isEmpty ? .secondary : .primary)

                    // Error
                    if let err = errorMessage {
                        ErrorBanner(message: err)
                    }

                    // Contact button — only shown to other users, not the seller
                    if let user = authVM.currentUser, user.id != listing.sellerId {
                        Button {
                            Task { await startConversation(currentUser: user) }
                        } label: {
                            Group {
                                if isContacting {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Message \(listing.sellerName)", systemImage: "bubble.left.fill")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.limbGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isContacting)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
        // Navigate to ChatView once a conversationId is ready.
        .navigationDestination(isPresented: $showChat) {
            if let convId = conversationId {
                ChatView(conversationId: convId, otherUserName: listing.sellerName)
                    .environmentObject(authVM)
            }
        }
    }

    // MARK: — Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func startConversation(currentUser: User) async {
        isContacting = true
        errorMessage = nil
        defer { isContacting = false }

        do {
            let convId = try await msgVM.getOrCreateConversation(
                currentUserId:   currentUser.id,
                currentUserName: currentUser.name,
                otherUserId:     listing.sellerId,
                otherUserName:   listing.sellerName,
                listing:         listing
            )
            conversationId = convId
            showChat       = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
