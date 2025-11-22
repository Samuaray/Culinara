import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Collection.createdAt, order: .reverse) private var collections: [Collection]

    @State private var showCreateCollection = false
    @State private var selectedCollection: Collection?

    var body: some View {
        NavigationStack {
            ScrollView {
                if collections.isEmpty {
                    EmptyStateView(
                        icon: "folder.fill",
                        title: "No Collections Yet",
                        message: "Organize your recipes into collections"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection)
                                .onTapGesture {
                                    selectedCollection = collection
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCollection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                CreateCollectionView()
            }
            .sheet(item: $selectedCollection) { collection in
                CollectionDetailView(collection: collection)
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: Collection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe Preview Grid
            if !collection.recipes.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4)
                ], spacing: 4) {
                    ForEach(collection.recipes.prefix(4)) { recipe in
                        if let imageData = recipe.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 80)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 80)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 160)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No recipes yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)

                if let description = collection.collectionDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text("\(collection.recipes.count) recipes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Create Collection View

struct CreateCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createCollection() {
        let collection = Collection(
            name: name,
            description: description.isEmpty ? nil : description
        )

        modelContext.insert(collection)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Collection Detail View

struct CollectionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let collection: Collection

    var body: some View {
        NavigationStack {
            ScrollView {
                if collection.recipes.isEmpty {
                    EmptyStateView(
                        icon: "tray.fill",
                        title: "No Recipes",
                        message: "Add recipes to this collection"
                    )
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(collection.recipes) { recipe in
                            RecipeCard(recipe: recipe)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(collection.name)
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
}

#Preview {
    CollectionsView()
        .modelContainer(for: [Collection.self, Recipe.self], inMemory: true)
}
