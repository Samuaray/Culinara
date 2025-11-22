import SwiftUI
import SwiftData

struct RecipeFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var selectedMealType: MealType?
    @State private var selectedRecipe: Recipe?

    var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty ||
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.recipeDescription?.localizedCaseInsensitiveContains(searchText) == true

            let matchesMealType = selectedMealType == nil || recipe.mealType == selectedMealType

            return matchesSearch && matchesMealType
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedMealType == nil
                            ) {
                                selectedMealType = nil
                            }

                            ForEach(MealType.allCases, id: \.self) { mealType in
                                FilterChip(
                                    title: mealType.rawValue,
                                    icon: mealType.icon,
                                    isSelected: selectedMealType == mealType
                                ) {
                                    selectedMealType = mealType
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))

                    // Recipe Cards
                    if filteredRecipes.isEmpty {
                        EmptyStateView(
                            icon: "book.closed.fill",
                            title: "No Recipes Yet",
                            message: "Tap the + button to create your first recipe"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredRecipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Culinara")
            .searchable(text: $searchText, prompt: "Search recipes...")
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe Card Component

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe Image
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
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
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.8))
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                // Title and Meal Type
                HStack {
                    Text(recipe.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    Spacer()

                    if let mealType = recipe.mealType {
                        Image(systemName: mealType.icon)
                            .foregroundStyle(.secondary)
                    }
                }

                // Description
                if let description = recipe.recipeDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Meta Information
                HStack(spacing: 16) {
                    Label("\(recipe.totalTime) min", systemImage: "clock.fill")
                    Label("\(recipe.servings) servings", systemImage: "person.2.fill")

                    Spacer()

                    // Difficulty Badge
                    Text(recipe.difficulty.rawValue)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(recipe.difficulty).opacity(0.2))
                        .foregroundStyle(difficultyColor(recipe.difficulty))
                        .clipShape(Capsule())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Empty State Component

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.semibold))

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    RecipeFeedView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
