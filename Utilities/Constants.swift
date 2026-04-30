import SwiftUI

// MARK: — Brand Color

extension Color {
    /// LimbSwap's signature green (#22c55e). Use this everywhere instead of Color.green.
    static let limbGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
}

// MARK: — App-wide Constants

/// Namespace for all magic strings and shared values.
struct K {

    // Firestore collection names — avoids typo-prone string literals scattered in code.
    struct Firestore {
        static let users         = "users"
        static let listings      = "listings"
        static let conversations = "conversations"
        static let messages      = "messages"
    }

    // Quick-reply prompts shown as chips in the chat input bar.
    struct Chat {
        static let quickPrompts = [
            "Interested! Is this still available?",
            "Can we meet up locally?",
            "Is shipping an option?",
            "What size is this exactly?",
            "I would love to trade!"
        ]
    }
}
