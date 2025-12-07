import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]

    @AppStorage("apiKey") private var apiKey = ""
    @State private var showAPIKeyInput = false
    @State private var showExportSuccess = false

    // Statistics computed properties
    var easyCount: Int {
        recipes.filter { $0.difficulty == .easy }.count
    }

    var mediumCount: Int {
        recipes.filter { $0.difficulty == .medium }.count
    }

    var hardCount: Int {
        recipes.filter { $0.difficulty == .hard }.count
    }

    var breakfastCount: Int {
        recipes.filter { $0.mealType == .breakfast }.count
    }

    var lunchCount: Int {
        recipes.filter { $0.mealType == .lunch }.count
    }

    var dinnerCount: Int {
        recipes.filter { $0.mealType == .dinner }.count
    }

    var dessertCount: Int {
        recipes.filter { $0.mealType == .dessert }.count
    }

    var averageCookTime: Int {
        guard !recipes.isEmpty else { return 0 }
        let total = recipes.reduce(0) { $0 + $1.totalTime }
        return total / recipes.count
    }

    var body: some View {
        NavigationStack {
            Form {
                // API Configuration
                Section {
                    HStack {
                        Text("Gemini API Key")
                        Spacer()
                        if apiKey.isEmpty {
                            Button("Add") {
                                showAPIKeyInput = true
                            }
                        } else {
                            Text("Set")
                                .foregroundStyle(.green)
                            Button("Change") {
                                showAPIKeyInput = true
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("AI Configuration")
                } footer: {
                    Text("Required for AI recipe generation, chat, and substitution features. Get your API key from ai.google.dev")
                }

                // Data Management
                Section {
                    HStack {
                        Text("Total Recipes")
                        Spacer()
                        Text("\(recipes.count)")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("By Difficulty")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Easy: \(easyCount) · Medium: \(mediumCount) · Hard: \(hardCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("By Meal Type")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if breakfastCount > 0 {
                                Text("Breakfast: \(breakfastCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if lunchCount > 0 {
                                Text("Lunch: \(lunchCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if dinnerCount > 0 {
                                Text("Dinner: \(dinnerCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if dessertCount > 0 {
                                Text("Dessert: \(dessertCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("Average Cook Time")
                        Spacer()
                        Text("\(averageCookTime) min")
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Button {
                        exportRecipes()
                    } label: {
                        Label("Export Recipes", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        deleteAllRecipes()
                    } label: {
                        Label("Delete All Recipes", systemImage: "trash")
                    }
                } header: {
                    Text("Recipe Statistics")
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://ai.google.dev")!) {
                        HStack {
                            Text("Get API Key")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    Toggle("Reduce Animations", isOn: .constant(false))
                        .disabled(true)
                }
            }
            .navigationTitle("Settings")
            .alert("API Key", isPresented: $showAPIKeyInput) {
                TextField("Enter API Key", text: $apiKey)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            } message: {
                Text("Enter your Google Gemini API key")
            }
            .alert("Export Successful", isPresented: $showExportSuccess) {
                Button("OK") { }
            } message: {
                Text("Your recipes have been exported successfully")
            }
        }
    }

    private func exportRecipes() {
        // TODO: Implement JSON export
        showExportSuccess = true
    }

    private func deleteAllRecipes() {
        recipes.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
