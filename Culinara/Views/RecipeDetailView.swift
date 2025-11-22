import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe

    @State private var showChat = false
    @State private var showSubstitution = false
    @State private var selectedIngredient: Ingredient?
    @State private var servings: Int
    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servings)
    }

    var servingMultiplier: Double {
        Double(servings) / Double(recipe.servings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image
                    if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 300)
                            .overlay {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 72))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Title and Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.largeTitle.weight(.bold))

                            if let description = recipe.recipeDescription {
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Meta Info
                        HStack(spacing: 20) {
                            MetaInfoItem(icon: "clock.fill", text: "\(recipe.totalTime) min")
                            MetaInfoItem(icon: "person.2.fill", text: "\(recipe.servings) servings")
                            MetaInfoItem(icon: "flame.fill", text: recipe.difficulty.rawValue)
                        }

                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                showSubstitution = true
                            } label: {
                                Label("Magic Sub", systemImage: "wand.and.stars")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showChat = true
                            } label: {
                                Label("Chat", systemImage: "message.fill")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: recipe.title) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        // Ingredients Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Ingredients")
                                    .font(.title2.weight(.bold))

                                Spacer()

                                // Servings Stepper
                                HStack(spacing: 12) {
                                    Button {
                                        if servings > 1 {
                                            servings -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                    }
                                    .disabled(servings <= 1)

                                    Text("\(servings)")
                                        .font(.headline)
                                        .frame(minWidth: 30)

                                    Button {
                                        servings += 1
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                    }
                                }
                                .foregroundStyle(.blue)
                            }

                            ForEach(recipe.ingredients) { ingredient in
                                IngredientRow(
                                    ingredient: ingredient,
                                    multiplier: servingMultiplier,
                                    onSubstitute: {
                                        selectedIngredient = ingredient
                                        showSubstitution = true
                                    }
                                )
                            }
                        }

                        Divider()

                        // Instructions Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Instructions")
                                .font(.title2.weight(.bold))

                            ForEach(recipe.instructions.sorted(by: { $0.stepNumber < $1.stepNumber })) { instruction in
                                InstructionRow(instruction: instruction)
                            }
                        }

                        // Nutrition (if available)
                        if let nutrition = recipe.nutrition {
                            Divider()

                            NutritionView(nutrition: nutrition)
                        }
                    }
                    .padding()
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditForm = true
                        } label: {
                            Label("Edit Recipe", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Recipe", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                ChatView(recipe: recipe)
            }
            .sheet(isPresented: $showSubstitution) {
                SubstitutionView(ingredient: selectedIngredient ?? recipe.ingredients.first!)
            }
            .sheet(isPresented: $showEditForm) {
                ManualRecipeFormView(recipeToEdit: recipe)
            }
            .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Recipe", role: .destructive) {
                    deleteRecipe()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \"\(recipe.title)\"? This action cannot be undone.")
            }
        }
    }

    // MARK: - Helper Methods

    private func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }
}

// MARK: - Supporting Views

struct MetaInfoItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

struct IngredientRow: View {
    @State private var isChecked = false
    let ingredient: Ingredient
    let multiplier: Double
    let onSubstitute: () -> Void

    var scaledQuantity: String {
        guard let quantity = ingredient.quantity else {
            return ingredient.item
        }

        let scaled = quantity * multiplier
        let formatted = scaled.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", scaled)
            : String(format: "%.1f", scaled)

        var text = formatted
        if let unit = ingredient.unit {
            text += " \(unit)"
        }
        text += " \(ingredient.item)"
        return text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                isChecked.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? .blue : .secondary)
            }

            Text(scaledQuantity)
                .strikethrough(isChecked)
                .foregroundStyle(isChecked ? .secondary : .primary)

            Spacer()

            Button {
                onSubstitute()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }
}

struct InstructionRow: View {
    let instruction: Instruction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(instruction.stepNumber)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(instruction.instruction)
                    .font(.body)

                if let timeMinutes = instruction.timeMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(timeMinutes) minutes")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let tip = instruction.tip {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(tip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

struct NutritionView: View {
    let nutrition: Nutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition (per serving)")
                .font(.title2.weight(.bold))

            HStack(spacing: 20) {
                NutritionItem(label: "Calories", value: "\(nutrition.calories)")
                NutritionItem(label: "Protein", value: "\(Int(nutrition.proteinG))g")
                NutritionItem(label: "Carbs", value: "\(Int(nutrition.carbsG))g")
                NutritionItem(label: "Fat", value: "\(Int(nutrition.fatG))g")
            }
        }
    }
}

struct NutritionItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)

    let recipe = Recipe(
        title: "Chicken Tikka Masala",
        description: "Rich, creamy Indian curry with tender chicken",
        cookTime: 30,
        prepTime: 15,
        servings: 4,
        difficulty: .medium,
        cuisine: "Indian",
        mealType: .dinner
    )
    container.mainContext.insert(recipe)

    return RecipeDetailView(recipe: recipe)
        .modelContainer(container)
}
