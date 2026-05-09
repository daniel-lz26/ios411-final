import SwiftUI
import PhotosUI

// Form for posting a new listing. Uses PhotosPicker for image selection.
struct CreateListingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ListingViewModel()

    // PhotosPicker selection state
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                // MARK: — Photos section
                Section("Photos") {
                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 1, matching: .images) {
                        Label(
                            vm.selectedImages.isEmpty ? "Add a Photo" : "1 photo selected",
                            systemImage: "photo.badge.plus"
                        )
                    }
                    .onChange(of: pickerItems) { items in
                        Task { await loadImages(from: items) }
                    }

                    Text("One photo per listing (stored securely in database)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Preview thumbnails
                    if !vm.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.selectedImages.indices, id: \.self) { i in
                                    Image(uiImage: vm.selectedImages[i])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                // MARK: — Item details section
                Section("Item Details") {
                    TextField("Title (e.g. Nike Air Max, Size 10 Right)", text: $vm.title)

                    Picker("Category", selection: $vm.category) {
                        ForEach(Listing.Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Size", text: $vm.size)

                    Picker("Side", selection: $vm.side) {
                        ForEach(Listing.Side.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Condition", selection: $vm.condition) {
                        ForEach(Listing.Condition.allCases, id: \.self) { cond in
                            Text(cond.rawValue).tag(cond)
                        }
                    }

                    Picker("Trade Type", selection: $vm.tradeType) {
                        ForEach(Listing.TradeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: — Description section
                Section("Description") {
                    TextEditor(text: $vm.description)
                        .frame(minHeight: 80)
                }

                // MARK: — Error / feedback
                if let error = vm.errorMessage {
                    Section {
                        ErrorBanner(message: error)
                    }
                }

                // MARK: — Post button
                Section {
                    Button {
                        guard let user = authVM.currentUser else { return }
                        Task { await vm.postListing(seller: user) }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Post Listing")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .listRowBackground(formIsValid ? Color.limbGreen : Color.gray)
                    .foregroundColor(.white)
                    .disabled(!formIsValid || vm.isLoading)
                }
            }
            .navigationTitle("Post a Listing")
            // Show a success alert and reset the form after a successful post.
            .alert("Listing Posted!", isPresented: Binding(
                get:  { vm.successMessage != nil },
                set:  { if !$0 { vm.successMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.successMessage ?? "")
            }
        }
    }

    // MARK: — Helpers

    private var formIsValid: Bool {
        !vm.title.isEmpty && !vm.size.isEmpty
    }

    /// Converts PhotosPickerItems to UIImages and stores them in the ViewModel.
    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) {
                images.append(img)
            }
        }
        vm.selectedImages = images
    }
}
