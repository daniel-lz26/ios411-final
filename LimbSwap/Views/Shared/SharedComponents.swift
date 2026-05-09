import SwiftUI

// MARK: — Base64ImageView

/// Renders an image from a base64 string, or shows a placeholder icon if absent.
struct Base64ImageView: View {
    let base64: String?
    let fallbackIcon: String      // SF Symbol name
    let fallbackColor: Color

    var body: some View {
        if let base64 = base64,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(fallbackColor.opacity(0.15))
                .overlay(
                    Image(systemName: fallbackIcon)
                        .font(.title2)
                        .foregroundColor(fallbackColor)
                )
        }
    }
}

// MARK: — ListingRow

/// A compact horizontal row for displaying a listing in a list (Profile, Search results).
struct ListingRow: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Base64ImageView(
                base64: listing.imageBase64,
                fallbackIcon: "photo",
                fallbackColor: Color(.systemGray3)
            )
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
