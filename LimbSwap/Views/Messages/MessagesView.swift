import SwiftUI

// Shows all conversations for the current user. Tapping opens ChatView.
struct MessagesView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = MessageViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading messages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.conversations.isEmpty {
                    emptyState
                } else {
                    List(vm.conversations) { conversation in
                        NavigationLink(destination: ChatView(
                            conversationId: conversation.id,
                            otherUserName:  conversation.otherUserName
                        ).environmentObject(authVM)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .task {
                if let userId = authVM.currentUser?.id {
                    await vm.loadConversations(for: userId)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No messages yet")
                .font(.headline)
            Text("Tap 'Message Seller' on any listing to start a conversation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: — Conversation Row

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.limbGreen.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(conversation.otherUserName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.limbGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName)
                    .font(.subheadline.weight(.semibold))
                Text(conversation.listingTitle)
                    .font(.caption)
                    .foregroundColor(.limbGreen)
                    .lineLimit(1)
                Text(conversation.lastMessage.isEmpty ? "No messages yet" : conversation.lastMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(conversation.lastMessageDate.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: — Chat View

// Real-time chat screen for a single conversation.
struct ChatView: View {
    let conversationId: String
    let otherUserName:  String

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = MessageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { message in
                            MessageBubble(
                                message:        message,
                                isFromCurrentUser: message.senderId == authVM.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                // Scroll to the latest message whenever messages update.
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Quick-reply chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(K.Chat.quickPrompts, id: \.self) { prompt in
                        Button(prompt) {
                            vm.messageText = prompt
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Message…", text: $vm.messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button {
                    guard let userId = authVM.currentUser?.id else { return }
                    Task {
                        await vm.sendMessage(
                            conversationId: conversationId,
                            senderId:       userId
                        )
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(vm.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? .secondary : .limbGreen)
                }
                .disabled(vm.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear  { vm.listenForMessages(conversationId: conversationId) }
        .onDisappear { vm.stopListening() }
    }
}

// MARK: — Message Bubble

private struct MessageBubble: View {
    let message:           Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isFromCurrentUser ? Color.limbGreen : Color(.systemGray5))
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .cornerRadius(18)
                .frame(maxWidth: 260, alignment: isFromCurrentUser ? .trailing : .leading)

            if !isFromCurrentUser { Spacer() }
        }
    }
}
