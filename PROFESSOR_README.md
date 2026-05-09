# LimbSwap — Professor Setup Guide

Thank you for reviewing LimbSwap. This guide will get the app running
on your Mac in under 10 minutes.

---

## What You Will Need

- A Mac with Xcode 15 or later installed
- The GoogleService-Info.plist file (provided separately via email)
- An internet connection (for Firebase)

---

## Step 1 — Clone the Repository

Open Terminal and run:

    git clone https://github.com/YOUR_USERNAME/LimbSwap.git
    cd LimbSwap

---

## Step 2 — Add the Firebase Config File

You should have received a file called GoogleService-Info.plist via email.

1. Open Finder and locate GoogleService-Info.plist
2. Open the LimbSwap project in Xcode by double-clicking LimbSwap.xcodeproj
3. In the Xcode file navigator (left sidebar), drag GoogleService-Info.plist
   directly into the LimbSwap folder (the one containing App/, Models/, etc.)
4. When prompted, make sure "Copy items if needed" is checked
5. Make sure "Add to target: LimbSwap" is checked
6. Click Finish

---

## Step 3 — Install Firebase via Swift Package Manager

Firebase should already be configured in the project. If you see a prompt
to resolve packages when Xcode opens, click Resolve Packages and wait for
it to finish (may take 1-2 minutes).

If packages do not resolve automatically:
1. File → Add Package Dependencies
2. Paste: https://github.com/firebase/firebase-ios-sdk
3. Select: FirebaseAuth, FirebaseFirestore
4. Click Add Package

---

## Step 4 — Build and Run

1. At the top of Xcode, select a simulator — iPhone 15 or iPhone 16 works best
2. Press Cmd + R to build and run
3. Wait for the simulator to launch (first build may take 2-3 minutes)

---

## Step 5 — Test Accounts

The app seeds test data automatically on first launch. Use either of these
accounts to log in:

| Email                  | Password   | Profile                        |
|------------------------|------------|-------------------------------|
| user1@limbswap.com     | Test1234!  | Marcus T. — Left below-knee   |
| user2@limbswap.com     | Test1234!  | Sarah K. — Right below-elbow  |

Logging in as user1 will show right-side listings (opposite of left amputation).
Logging in as user2 will show left-side listings (opposite of right amputation).

This demonstrates the core smart-filtering feature of the app.

---

## Core Features to Test

Golden path (recommended order):

1. Log in as user1@limbswap.com
2. Notice the home feed shows right-side items automatically
3. Tap any listing to view details
4. Tap "Message Seller" to open a chat
5. Send a message using the quick prompts or type your own
6. Switch to the Post tab and create a new listing
7. Switch to the Search tab and use the side/category filters

---

## Known Limitations

- Image upload: Firebase Storage requires Google Cloud billing which is
  unavailable for this student project. Images are stored as compressed
  base64 strings in Firestore instead. Seed listings show placeholder
  icons; new listings posted during testing will display uploaded photos.

- Push notifications: APNs integration requires a paid Apple Developer
  account. Messaging works in real time within the app but no background
  notifications are sent.

---

## Project Structure

    LimbSwap/
    ├── App/            Entry point, navigation, Firebase init
    ├── Models/         User, Listing, Message structs
    ├── ViewModels/     @MainActor classes — auth, feed, listing, chat
    ├── Services/       Firebase wrappers — auth, listings, messages
    ├── Views/          All SwiftUI screens
    └── Utilities/      Constants, seed data

Architecture follows MVVM. All Firebase calls use Swift async/await.

---

## Troubleshooting

Problem: "No such module FirebaseFirestore"
Fix: File → Packages → Resolve Package Versions, wait and rebuild

Problem: Feed is empty after login
Fix: The seed runs on first launch. Wait 5 seconds and pull to refresh,
or force-quit and relaunch the app once.

Problem: GoogleService-Info.plist error at build
Fix: Make sure the plist is added to the LimbSwap target (not just copied
into the folder). Right-click it in Xcode → Show File Inspector →
check the box next to LimbSwap under Target Membership.

---

## Contact

Daniel Lopez
CPSC 411 — Final Project
