import SwiftUI
import SwiftData

struct AIGenerationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var ingredientsText = ""
    @State private var selectedCuisine = ""
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var targetCookTime = 30

    @State private var isGenerating = false
    @State private var generatedRecipe: Recipe?
    @State private var errorMessage: String?

    @StateObject private var geminiService = GeminiService()

    var ingredientsList: [String] {
        ingredientsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("AI Recipe Generator")
                                .font(.largeTitle.weight(.bold))
                        }

                        Text("List your ingredients and let AI create a delicious recipe")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Ingredients Input
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Ingredients", systemImage: "list.bullet")
                            .font(.headline)

                        ZStack(alignment: .topLeading) {
                            if ingredientsText.isEmpty {
                                Text("chicken breast\nbell peppers\ncoconut milk\nginger\ngarlic")
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                            }

                            TextEditor(text: $ingredientsText)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }

                        if !ingredientsList.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ingredientsList, id: \.self) { ingredient in
                                        Text(ingredient)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Preferences (Optional)", systemImage: "slider.horizontal.3")
                            .font(.headline)

                        // Cuisine
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cuisine")
                                .font(.subheadline.weight(.medium))

                            TextField("e.g., Italian, Thai, Mexican", text: $selectedCuisine)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Difficulty")
                                .font(.subheadline.weight(.medium))

                            Picker("Difficulty", selection: $selectedDifficulty) {
                                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                    Text(difficulty.rawValue).tag(difficulty)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Cook Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Cook Time: \(targetCookTime) min")
                                .font(.subheadline.weight(.medium))

                            Slider(value: Binding(
                                get: { Double(targetCookTime) },
                                set: { targetCookTime = Int($0) }
                            ), in: 15...120, step: 15)
                        }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Generate Button
                    Button {
                        generateRecipe()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }

                            Text(isGenerating ? "Generating..." : "Generate Recipe")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            ingredientsList.isEmpty || isGenerating
                                ? Color.gray
                                : Color.blue
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(ingredientsList.isEmpty || isGenerating)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $generatedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    private func generateRecipe() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let recipe = try await geminiService.generateRecipe(
                    ingredients: ingredientsList,
                    cuisine: selectedCuisine.isEmpty ? nil : selectedCuisine,
                    difficulty: selectedDifficulty,
                    targetCookTime: targetCookTime
                )

                await MainActor.run {
                    modelContext.insert(recipe)
                    try? modelContext.save()

                    generatedRecipe = recipe
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

#Preview {
    AIGenerationView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
