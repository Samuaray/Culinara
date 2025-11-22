import SwiftUI
import SwiftData
import PhotosUI

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var creationMethod: CreationMethod = .manual
    @State private var showAIGeneration = false

    enum CreationMethod {
        case manual
        case ai
        case url
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Create a Recipe")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 32)

                VStack(spacing: 16) {
                    // AI Generation Button
                    CreationMethodCard(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "Generate with AI",
                        description: "Create a recipe from ingredients using AI",
                        gradient: [.purple.opacity(0.6), .pink.opacity(0.6)]
                    ) {
                        creationMethod = .ai
                        showAIGeneration = true
                    }

                    // Manual Entry Button
                    CreationMethodCard(
                        icon: "pencil",
                        iconColor: .blue,
                        title: "Manual Entry",
                        description: "Write your own recipe from scratch",
                        gradient: [.blue.opacity(0.6), .cyan.opacity(0.6)]
                    ) {
                        creationMethod = .manual
                        // Navigate to manual form
                    }

                    // Import from URL Button
                    CreationMethodCard(
                        icon: "link",
                        iconColor: .green,
                        title: "Import from URL",
                        description: "Paste a recipe URL to import automatically",
                        gradient: [.green.opacity(0.6), .teal.opacity(0.6)]
                    ) {
                        creationMethod = .url
                        // Show URL input
                    }

                    // Scan Recipe Button
                    CreationMethodCard(
                        icon: "camera.fill",
                        iconColor: .orange,
                        title: "Scan Recipe",
                        description: "Take a photo of a recipe card or cookbook",
                        gradient: [.orange.opacity(0.6), .red.opacity(0.6)]
                    ) {
                        // Show camera
                    }
                }
                .padding()

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAIGeneration) {
                AIGenerationView()
            }
        }
    }
}

// MARK: - Creation Method Card

struct CreationMethodCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateRecipeView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
