import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    @StateObject private var geminiService = GeminiService()

    let suggestedQuestions = [
        "Can I make this ahead?",
        "What can I substitute?",
        "How do I know when it's done?",
        "Can I double this recipe?",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome Message
                            if messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "chef.hat.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    Text("Chat with Sous Chef")
                                        .font(.title2.weight(.bold))

                                    Text("Ask me anything about \"\(recipe.title)\"")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)

                                    // Suggested Questions
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Try asking:")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)

                                        ForEach(suggestedQuestions, id: \.self) { question in
                                            Button {
                                                inputText = question
                                            } label: {
                                                Text(question)
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color(.systemGray6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding()
                                }
                                .padding(.top, 40)
                            }

                            // Messages
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Loading Indicator
                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Area
                HStack(spacing: 12) {
                    TextField("Ask a question...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Sous Chef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: question)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        // Get AI response
        Task {
            do {
                let response = try await geminiService.chatWithRecipe(
                    recipe: recipe,
                    question: question,
                    history: messages
                )

                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response)
                    messages.append(assistantMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        content: "Sorry, I encountered an error. Please try again."
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: message.role == .user ? 16 : 4,
                            bottomTrailingRadius: message.role == .user ? 4 : 16,
                            topTrailingRadius: 16
                        )
                    )

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let createdAt = Date()

    enum Role {
        case user
        case assistant
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)

    let recipe = Recipe(
        title: "Chicken Tikka Masala",
        description: "Rich, creamy Indian curry",
        cookTime: 30,
        prepTime: 15
    )

    return ChatView(recipe: recipe)
        .modelContainer(container)
}
