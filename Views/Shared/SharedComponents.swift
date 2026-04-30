import SwiftUI

// MARK: — ListingRow

/// A compact horizontal row for displaying a listing in a list (Profile, Search results).
struct ListingRow: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: listing.imageURLs.first ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(Image(systemName: "photo").foregroundColor(.secondary))
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    TagChip(text: listing.side.rawValue, color: .limbGreen)
                    TagChip(text: listing.condition.rawValue, color: .secondary)
                }

                Text(listing.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(listing.tradeType.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundColor(listing.tradeType == .free ? .limbGreen : .orange)
        }
        .padding(.vertical, 4)
    }
}

// MARK: — FilterChip

/// A tappable pill-shaped filter button. Highlights in limbGreen when selected.
struct FilterChip: View {
    let title:    String
    let isSelected: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.limbGreen : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: — TagChip

/// A non-interactive small label badge used inside cards and rows.
struct TagChip: View {
    let text:  String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: — ErrorBanner

/// A red banner used to surface error messages to the user.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.white)
            .padding(10)
            .background(Color.red.opacity(0.85))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}
