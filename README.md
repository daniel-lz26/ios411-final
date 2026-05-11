# LimbSwap

**Developer:** Daniel Lopez | **Course:** CPSC 411 — Final Project | **Due:** May 10, 2026

---

## 1. Project Overview

LimbSwap is a peer-to-peer iOS marketplace built exclusively for amputees to trade and donate single-sided clothing and footwear. The problem it addresses is simple but overlooked: a person who has lost their left leg below the knee only ever wears one shoe from each pair. The second shoe is perfectly good but has no use to them — and it is exactly what a right-side amputee needs. No mainstream marketplace (eBay, Poshmark, Facebook Marketplace) acknowledges this reality or provides any filtering for it. Sellers are forced to post in generic categories, and buyers must scroll through irrelevant results to find the single item that matches their specific need.

LimbSwap was built to solve that problem end-to-end. Users register with their amputation profile — type (above knee, below knee, above elbow, below elbow) and affected side (left, right, or both). The home feed then automatically queries Firestore for listings of the opposite side. A left-side amputee sees only right-side listings without touching a single filter. This smart filtering is the core original contribution of the app and the feature that distinguishes it from any existing platform.

The app was built for CPSC 411 by Daniel Lopez as a full-stack iOS project demonstrating SwiftUI, Firebase Authentication, Cloud Firestore, and MVVM architecture in a real-world, socially meaningful context.

---

## 2. Goals of the Project

The primary goal of LimbSwap is to give amputees a dedicated, frictionless place to exchange single-sided items. The core hypothesis is that the amputation profile collected at sign-up is sufficient to automatically surface relevant listings for any user, eliminating the manual filtering that makes existing platforms so frustrating for this community. Every architectural and feature decision was made in service of that experience.

The secondary goals are equally important from a coursework perspective. First, the project demonstrates a complete MVVM (Model-View-ViewModel) architecture in SwiftUI where each layer has a well-defined responsibility and no layer reaches into another's domain. Second, it demonstrates real-time Firebase integration: both user data and chat messages are driven by Firestore snapshot listeners that update the UI without polling. Third, it follows SwiftUI best practices including `@MainActor` view models, `async/await` concurrency, `@Published` state management, and separation of concerns between views and business logic. Fourth, the interface was designed with accessibility in mind — large tap targets, color choices with sufficient contrast, and clear labels — because the user base for this app may include people with limited dexterity in one hand.

This app was chosen as the final project because the idea is genuinely original and the real-world impact is concrete. Amputees have a real problem that no software currently solves well. Building something that could actually help people  not just a to-do list or weather app clone  made every hard technical problem more worth solving.

---

## 3. Functionalities

### User Registration and Amputation Profile Setup

When a new user opens LimbSwap they are presented with the login screen, which links to a sign-up form. The sign-up form collects standard fields (name, email, password, city) and then requires the user to complete their amputation profile: amputation type (Above Knee, Below Knee, Above Elbow, Below Elbow) and affected side (Left, Right, Both). These two fields are stored in the `users` Firestore collection alongside the rest of the profile. They are the inputs to the smart feed query described in the next section. The sign-up flow uses Firebase Authentication to create the account and immediately writes a corresponding user document to Firestore using the same UID as the auth record, which is how the app links auth identity to profile data throughout the session.

### Profile-Based Smart Feed

The home feed is the defining feature of LimbSwap. When a user logs in, `HomeViewModel` reads the user's `affectedSide` field from Firestore. It then queries the `listings` collection with a `where("side", isEqualTo: oppositeSide)` filter, where `oppositeSide` is computed by simply flipping `Left` to `Right` and vice versa. Users with `Both` see all listings. The result is a personalized feed with zero configuration required from the user after sign-up.

The feed is rendered as a two-column `LazyVGrid` of `ListingCard` components. Each card shows the listing photo (rendered from base64), title, category, condition, side, trade type (Free or Trade), and location. Tapping a card opens the full listing detail view.

### Listing Creation with Base64 Image Storage

The Post tab opens `CreateListingView`, a form where the user fills in title, category, size, side, condition, trade type, description, and location, and optionally attaches a photo using `PhotosPicker` from the `PhotosUI` framework. When a photo is selected, `ListingViewModel` uses `ImageRenderer` to compress the image to a maximum width of 600 pixels at 40% JPEG quality. The compressed data is then base64-encoded and stored as a string in the `imageBase64` field of the listing document.

Firebase Cloud Storage would be the standard solution for image hosting, but it requires linking a Google Cloud billing account. That is not available for this student project, so base64 in Firestore was chosen as the workaround. At the compression settings above a typical phone photo compresses to well under 100 KB, keeping documents far below Firestore's 1 MB document limit. This approach preserves full image functionality with no external storage dependency.

When the form is submitted, `ListingService.createListing(_:)` writes the document to Firestore and the listing immediately appears in the home feed for users with the matching opposite side.

### Browse and Search with Filters

The Search tab provides a text search field combined with a row of `FilterChip` toggles for side (Left / Right), category (Shoe, Glove, Sleeve, Prosthetic Accessory, Clothing, Other), condition (New, Like New, Good, Fair), and trade type (Free / Trade). Filtering is performed client-side on the full listings collection. The search field matches against title, description, and category. Filters compose additively — the user can combine any number of chips to narrow results precisely.

### Listing Detail View

Tapping any listing opens `ListingDetailView`, which displays the full photo, all listing fields, the seller's name and location, and a prominent "Message Seller" button. The detail view is read-only for browsing users. When the logged-in user owns the listing, the message button is hidden.

### Real-Time Messaging

Tapping "Message Seller" creates or reopens a conversation in the `conversations` Firestore collection and opens `ChatView`. Conversations are identified by a composite key of the two participant UIDs and the listing ID to prevent duplicate threads. `MessageViewModel` attaches a Firestore snapshot listener to the `messages` subcollection of the active conversation using `addSnapshotListener`. Every time a new message document is written to Firestore — by either participant, on any device — the listener fires and the UI updates in real time without any manual refresh.

Messages are rendered as `MessageBubble` views that align right (sent) or left (received) based on whether the `senderId` matches the current user's UID. The chat also includes a row of quick-reply prompt buttons pre-loaded from `Constants.swift` — phrases like "Is this still available?" and "What size is this?" — that let users start conversations with a single tap.

### Profile View

The Profile tab displays the logged-in user's name, email, city, and amputation profile, followed by a grid of their own active listings. It also includes a Sign Out button that calls `AuthViewModel.signOut()`, which calls `Auth.auth().signOut()` and clears local session state. After sign-out the app returns to the login screen via the `ContentView` auth gate.

---

## 4. Architecture and Design

### MVVM Overview

LimbSwap follows the Model-View-ViewModel (MVVM) architectural pattern throughout. The primary motivation for choosing MVVM in a SwiftUI project is that SwiftUI views are already designed to be reactive — they observe state and re-render automatically — which maps cleanly onto the ViewModel layer's role as a publisher of state. Keeping business logic and Firebase calls out of views makes each layer independently testable and dramatically easier to debug.

### Models

Models are plain Swift `struct` types that conform to `Codable` and `Identifiable`. `User`, `Listing`, and `Message` are defined in the `Models/` directory. Because Firestore documents are JSON-like, the `Codable` conformance allows straightforward encoding and decoding with `Firestore.Decoder` and `Firestore.Encoder`. Enums like `AmputationType`, `Side`, `Category`, `Condition`, and `TradeType` are defined as `String`-backed enums so their raw values are stored directly in Firestore without any translation layer.

### ViewModels

All ViewModels are classes annotated with `@MainActor` and conform to `ObservableObject`. State properties use `@Published` so SwiftUI views automatically re-render when they change. All Firebase-calling methods are `async` functions invoked with `Task { await ... }` from view lifecycle callbacks, keeping the UI thread free. Each ViewModel has a focused responsibility:

- `AuthViewModel` manages login, sign-up, sign-out, and the `currentUser` session object that gates the entire app.
- `HomeViewModel` owns the smart-feed query and the resulting `listings` array.
- `ListingViewModel` owns the create-listing form state, image compression, and the `createListing` call.
- `MessageViewModel` owns the conversations list and the real-time chat listener for the active conversation.

### Services

Service files are singletons that wrap all direct Firebase SDK calls. `AuthService` wraps `Firebase Authentication` and the user profile Firestore reads and writes. `ListingService` wraps the listings collection CRUD and the base64 image conversion helper. `MessageService` wraps conversation creation, message sending, and the snapshot listener. Isolating Firebase calls in services means that if the backend ever changes (for example, upgrading from base64 to Firebase Storage), the change is contained to one file rather than spread across every ViewModel.

### Views

Views are pure SwiftUI — they observe a ViewModel via `@StateObject` or `@EnvironmentObject` and render from its `@Published` state. They contain no business logic and make no Firebase calls directly. `ContentView` acts as the auth gate: it observes `AuthViewModel` and conditionally renders either `LoginView` or `MainTabView` based on whether `currentUser` is non-nil. `MainTabView` wraps the five primary destinations in a `TabView`.

### Firestore Data Model

The Firestore database uses three top-level collections:

**`users/{userId}`** stores the user profile. The `userId` matches the Firebase Authentication UID. Fields include `name`, `email`, `location`, `amputationType`, `affectedSide`, and `createdAt`.

**`listings/{listingId}`** stores each marketplace item. The `sellerId` field references the poster's UID. The `side` field (`"Left"` or `"Right"`) is what the smart feed queries against. The `imageBase64` field holds the compressed JPEG image as a base64 string. The `isActive` boolean allows future soft-delete without removing documents.

**`conversations/{conversationId}`** stores the metadata for each chat thread — participant IDs, associated listing, last message preview, and display names. The `messages/{messageId}` subcollection within each conversation stores individual messages with `senderId`, `text`, and `timestamp`. Keeping messages in a subcollection rather than an array field allows Firestore to paginate large threads efficiently and enables the snapshot listener to fire only on new messages rather than on every field update.

### Development Workflow

All Swift source files were written on a Windows machine using VS Code with the Swift extension and the official Swift for Windows toolchain. SwiftUI previews and the iOS simulator are macOS-exclusive, so the development workflow was: write and commit on Windows, push to GitHub, pull on a borrowed Mac, then build, run, and debug in Xcode. Git served as the bridge between the two environments. This cross-platform workflow added friction but was entirely workable, and it demonstrated that Swift development on Windows is a legitimate option for editors and server-side Swift, even though the final build step still requires a Mac.

### Project Structure

```
LimbSwap/
├── App/
│   ├── LimbSwapApp.swift          @main entry point — FirebaseApp.configure(), seed trigger
│   ├── ContentView.swift          Auth gate — renders LoginView or MainTabView
│   └── MainTabView.swift          TabView: Home, Search, Post, Messages, Profile
│
├── Models/
│   ├── User.swift                 User struct, AmputationType enum, Side enum
│   ├── Listing.swift              Listing struct, Category/Side/Condition/TradeType enums
│   └── Message.swift              Message struct, Conversation struct
│
├── ViewModels/
│   ├── AuthViewModel.swift        Login, sign-up, sign-out, currentUser session
│   ├── HomeViewModel.swift        Smart feed query (opposite-side filter)
│   ├── ListingViewModel.swift     Create-listing form state, base64 image, createListing
│   └── MessageViewModel.swift     Conversations list, real-time Firestore chat listener
│
├── Services/
│   ├── AuthService.swift          Firebase Auth wrapper + user profile Firestore CRUD
│   ├── ListingService.swift       Listings collection CRUD, base64 compression helper
│   └── MessageService.swift       Conversation creation, message send, snapshot listener
│
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift        Email + password form, link to sign-up
│   │   └── SignUpView.swift       Registration form with amputation profile fields
│   ├── Home/
│   │   └── HomeView.swift         LazyVGrid feed, ListingCard component
│   ├── Listings/
│   │   ├── ListingDetailView.swift Full listing detail, Message Seller button
│   │   ├── CreateListingView.swift Post new item form with PhotosPicker
│   │   └── SearchView.swift        Text search + FilterChip row
│   ├── Messages/
│   │   └── MessagesView.swift      Conversations list, ChatView, MessageBubble
│   ├── Profile/
│   │   └── ProfileView.swift       User info, amputation profile, own listings, sign out
│   └── Shared/
│       └── SharedComponents.swift  ListingRow, FilterChip, TagChip, Base64ImageView,
│                                   ErrorBanner, categoryIcon helper
│
└── Utilities/
    ├── Constants.swift             Color.limbGreen, K struct (Firestore keys, quick prompts)
    └── SeedData.swift              Seeds 8 listings and 2 test accounts on first launch
```

---

## 5. Documentation

### GitHub

The source code is hosted at:

```
https://github.com/daniel-lz26/ios411-final?tab=readme-ov-file#
```


### Deployment and Build Instructions

**Prerequisites**

- A Mac running macOS Ventura or later
- Xcode 15 or later (free from the Mac App Store)
- An active internet connection for Firebase
- The `GoogleService-Info.plist` file (provided separately — see below)

**Step 1 — Clone the repository**

```bash
git clone https://github.com/daniel-lz26/ios411-final?tab=readme-ov-file#
cd LimbSwap
```

**Step 2 — Add the Firebase configuration file**

`GoogleService-Info.plist` is the Firebase project configuration file that connects the app to the correct Firestore database. It is not checked into the repository for security reasons and must be added manually.

1. Open the project in Xcode: double-click `LimbSwap.xcodeproj`
2. In the Xcode file navigator (left sidebar), drag `GoogleService-Info.plist` into the `LimbSwap/` folder (the one that contains `App/`, `Models/`, etc.)
3. When the dialog appears, make sure "Copy items if needed" is checked and "Add to target: LimbSwap" is checked
4. Click Finish

**Step 3 — Resolve Firebase packages**

Firebase is added via Swift Package Manager. When Xcode opens the project it should prompt to resolve packages automatically. Click **Resolve Packages** and wait 1–2 minutes.

If packages do not resolve automatically:
1. File → Add Package Dependencies
2. Paste: `https://github.com/firebase/firebase-ios-sdk`
3. Select **FirebaseAuth** and **FirebaseFirestore**
4. Click Add Package

**Step 4 — Set Firestore security rules**

In the Firebase Console for the project, navigate to Firestore → Rules and paste the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

This allows any authenticated user to read and write, which is appropriate for a class project.

**Step 5 — Build and run**

1. At the top of Xcode, select a simulator — iPhone 15 or iPhone 16 recommended
2. Press **Cmd + R** to build and run
3. The first build may take 2–3 minutes while Firebase packages compile

**Step 6 — Seed data**

The app seeds 8 realistic listings and 2 test user accounts into Firestore automatically on first launch. No manual database setup is required. If the home feed appears empty after login, wait 5 seconds and pull to refresh, or force-quit and relaunch once.

### How to Run and Test the App

**Test accounts**

| Email | Password | Profile | Feed shows |
|---|---|---|---|
| user1@limbswap.com | Test1234! | Marcus T. — Left below-knee | Right-side listings |
| user2@limbswap.com | Test1234! | Sarah K. — Right below-elbow | Left-side listings |

Logging in as `user1` demonstrates the smart feed for a left-side amputee: the home screen automatically shows right-side items with no filtering required. Logging in as `user2` shows the mirror case. Comparing the two feeds side by side is the clearest demonstration of the core feature.

**Recommended golden path**

1. Log in as `user1@limbswap.com`
2. Observe the home feed — every listing shown is a right-side item
3. Tap any listing to open the detail view and read the full description
4. Tap **Message Seller** to open a chat thread
5. Send a message using a quick-reply prompt or by typing
6. Navigate to the **Post** tab and create a new listing with a photo from the simulator's photo library
7. Navigate to the **Search** tab and experiment with the side, category, and condition filters
8. Navigate to the **Profile** tab to see the user's amputation profile and their posted listings
9. Sign out, then log in as `user2@limbswap.com` and compare the home feed

---

## 6. Known Limitations and Future Work

### Firebase Storage

Firebase Cloud Storage requires a linked Google Cloud billing account with an active payment method. As a student, this was not available. Rather than drop image support entirely, images are compressed to a maximum of 600 pixels wide at 40% JPEG quality using `ImageRenderer` and stored as base64 strings in the listing's Firestore document. At those settings a typical photo compresses to roughly 60–90 KB, well within Firestore's 1 MB document limit. The workaround preserves full image functionality for photos taken during testing. Seed listings show category icons instead of photos because generating and embedding 8 base64 images at seed time would bloat the seed file. Upgrading to Firebase Storage when billing is available would require changing only `ListingService` — the rest of the app is already structured around an `imageURLs` field for future use.

### Push Notifications

APNs (Apple Push Notification service) integration requires enrollment in the Apple Developer Program, which costs $99 per year. Chat messages are delivered in real time while the app is open via Firestore snapshot listeners, but no background push notifications are sent when the app is closed. This is a known limitation for a student project.

### User Verification and Trust Ratings

A trust and reputation system (star ratings, verified amputee badge) was in the original project proposal but was descoped to keep the submission focused. The architecture is ready to support it — a `ratings` subcollection under `users/{userId}` would require no schema changes elsewhere.

### Future Improvements

- Push notifications via APNs when a developer account is available
- Location-based radius filtering using MapKit and Core Location
- Trust ratings and user verification with community feedback
- Firebase Storage upgrade for scalable image hosting
- Accessibility audit with VoiceOver to ensure full usability for one-handed users
- Community validation with real amputee users to refine the amputation profile options

---

## 7. Lessons Learned

**Set up the build environment before writing code.** Development started on Windows before confirming that a Mac would be available for testing. This meant several Swift APIs had to be discovered indirectly through documentation rather than by running code immediately. In a future project the first commit would be a buildable skeleton run on the actual target platform.

**Firebase test mode saves development time.** Early sessions were slowed down by Firestore permission errors because the security rules were too restrictive. Switching to open read/write rules during development and locking them down at the end was far more efficient than debugging permission errors interleaved with feature work.

**MVVM pays off during debugging.** Several bugs that appeared in the UI turned out to be state management issues in a ViewModel. Because business logic was isolated from views, it was possible to reason about and fix those bugs by reading a single file. In projects where logic is mixed into views this kind of isolation is not possible and debugging requires following a chain of side effects across many files.

**Cross-platform development with Git as the glue is viable.** Writing Swift on Windows and building on Mac was an unusual workflow, but Git handled it cleanly. Every push from Windows was a pull on Mac and vice versa, with no merge conflicts because work alternated linearly between the two machines. The lesson is that the tool (VS Code + Swift extension) matters less than the discipline of committing small, complete units of work so the other environment always has a clean starting point.
