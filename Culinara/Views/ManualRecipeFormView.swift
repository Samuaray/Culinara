import SwiftUI
import SwiftData
import PhotosUI

struct ManualRecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Recipe being edited (nil if creating new)
    var recipeToEdit: Recipe?

    // Form fields
    @State private var title = ""
    @State private var recipeDescription = ""
    @State private var cookTime = 30
    @State private var prepTime = 15
    @State private var servings = 4
    @State private var difficulty: Difficulty = .medium
    @State private var cuisine = ""
    @State private var mealType: MealType? = nil

    // Ingredients
    @State private var ingredients: [IngredientInput] = []
    @State private var newIngredientItem = ""
    @State private var newIngredientQuantity = ""
    @State private var newIngredientUnit = ""

    // Instructions
    @State private var instructions: [InstructionInput] = []
    @State private var newInstructionText = ""

    // Image
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // Validation
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var isEditing: Bool {
        recipeToEdit != nil
    }

    init(recipeToEdit: Recipe? = nil) {
        self.recipeToEdit = recipeToEdit

        // Initialize state from existing recipe if editing
        if let recipe = recipeToEdit {
            _title = State(initialValue: recipe.title)
            _recipeDescription = State(initialValue: recipe.recipeDescription ?? "")
            _cookTime = State(initialValue: recipe.cookTime)
            _prepTime = State(initialValue: recipe.prepTime)
            _servings = State(initialValue: recipe.servings)
            _difficulty = State(initialValue: recipe.difficulty)
            _cuisine = State(initialValue: recipe.cuisine ?? "")
            _mealType = State(initialValue: recipe.mealType)
            _selectedImageData = State(initialValue: recipe.imageData)

            // Convert existing ingredients
            _ingredients = State(initialValue: recipe.ingredients.map { ing in
                IngredientInput(
                    item: ing.item,
                    quantity: ing.quantity.map { String($0) } ?? "",
                    unit: ing.unit ?? ""
                )
            })

            // Convert existing instructions
            _instructions = State(initialValue: recipe.instructions
                .sorted(by: { $0.stepNumber < $1.stepNumber })
                .map { inst in
                    InstructionInput(
                        instruction: inst.instruction,
                        timeMinutes: inst.timeMinutes.map { String($0) } ?? "",
                        tip: inst.tip ?? ""
                    )
                }
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Recipe Title", text: $title)

                    TextField("Description (optional)", text: $recipeDescription, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Meal Type", selection: $mealType) {
                        Text("None").tag(nil as MealType?)
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as MealType?)
                        }
                    }

                    TextField("Cuisine (optional)", text: $cuisine)
                }

                // Time & Servings Section
                Section("Details") {
                    Stepper("Prep Time: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cook Time: \(cookTime) min", value: $cookTime, in: 0...480, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue).tag(diff)
                        }
                    }
                }

                // Image Section
                Section("Image") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "photo.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            VStack(alignment: .leading) {
                                Text("Add Photo")
                                    .font(.headline)
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }

                // Ingredients Section
                Section {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        HStack {
                            Text(ingredient.displayText)
                            Spacer()
                            Button(role: .destructive) {
                                ingredients.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    // Add ingredient form
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Ingredient")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("Qty", text: $newIngredientQuantity)
                                .frame(width: 50)
                                .keyboardType(.decimalPad)

                            TextField("Unit", text: $newIngredientUnit)
                                .frame(width: 60)

                            TextField("Ingredient", text: $newIngredientItem)

                            Button {
                                addIngredient()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            .disabled(newIngredientItem.isEmpty)
                        }
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Add at least one ingredient")
                }

                // Instructions Section
                Section {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Step \(index + 1)")
                                    .font(.headline)
                                Spacer()
                                Button(role: .destructive) {
                                    instructions.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(instruction.instruction)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { from, to in
                        instructions.move(fromOffsets: from, toOffset: to)
                    }

                    // Add instruction form
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Step")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Instruction", text: $newInstructionText, axis: .vertical)
                            .lineLimit(2...5)

                        Button {
                            addInstruction()
                        } label: {
                            Label("Add Step", systemImage: "plus.circle.fill")
                        }
                        .disabled(newInstructionText.isEmpty)
                    }
                } header: {
                    Text("Instructions")
                } footer: {
                    Text("Add at least one instruction step")
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        saveRecipe()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func addIngredient() {
        guard !newIngredientItem.isEmpty else { return }

        ingredients.append(IngredientInput(
            item: newIngredientItem,
            quantity: newIngredientQuantity,
            unit: newIngredientUnit
        ))

        newIngredientItem = ""
        newIngredientQuantity = ""
        newIngredientUnit = ""
    }

    private func addInstruction() {
        guard !newInstructionText.isEmpty else { return }

        instructions.append(InstructionInput(
            instruction: newInstructionText,
            timeMinutes: "",
            tip: ""
        ))

        newInstructionText = ""
    }

    private func validateForm() -> Bool {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a recipe title"
            showValidationAlert = true
            return false
        }

        if ingredients.isEmpty {
            validationMessage = "Please add at least one ingredient"
            showValidationAlert = true
            return false
        }

        if instructions.isEmpty {
            validationMessage = "Please add at least one instruction step"
            showValidationAlert = true
            return false
        }

        return true
    }

    private func saveRecipe() {
        guard validateForm() else { return }

        if let existingRecipe = recipeToEdit {
            // Update existing recipe
            existingRecipe.title = title
            existingRecipe.recipeDescription = recipeDescription.isEmpty ? nil : recipeDescription
            existingRecipe.cookTime = cookTime
            existingRecipe.prepTime = prepTime
            existingRecipe.servings = servings
            existingRecipe.difficulty = difficulty
            existingRecipe.cuisine = cuisine.isEmpty ? nil : cuisine
            existingRecipe.mealType = mealType
            existingRecipe.imageData = selectedImageData
            existingRecipe.updatedAt = Date()

            // Remove old ingredients and instructions
            existingRecipe.ingredients.forEach { modelContext.delete($0) }
            existingRecipe.instructions.forEach { modelContext.delete($0) }

            // Add new ingredients
            for ingredientInput in ingredients {
                let ingredient = Ingredient(
                    item: ingredientInput.item,
                    quantity: Double(ingredientInput.quantity),
                    unit: ingredientInput.unit.isEmpty ? nil : ingredientInput.unit
                )
                existingRecipe.ingredients.append(ingredient)
            }

            // Add new instructions
            for (index, instructionInput) in instructions.enumerated() {
                let instruction = Instruction(
                    stepNumber: index + 1,
                    instruction: instructionInput.instruction,
                    timeMinutes: Int(instructionInput.timeMinutes),
                    tip: instructionInput.tip.isEmpty ? nil : instructionInput.tip
                )
                existingRecipe.instructions.append(instruction)
            }
        } else {
            // Create new recipe
            let recipe = Recipe(
                title: title,
                description: recipeDescription.isEmpty ? nil : recipeDescription,
                cookTime: cookTime,
                prepTime: prepTime,
                servings: servings,
                difficulty: difficulty,
                cuisine: cuisine.isEmpty ? nil : cuisine,
                mealType: mealType,
                sourceType: .original
            )

            recipe.imageData = selectedImageData

            // Add ingredients
            for ingredientInput in ingredients {
                let ingredient = Ingredient(
                    item: ingredientInput.item,
                    quantity: Double(ingredientInput.quantity),
                    unit: ingredientInput.unit.isEmpty ? nil : ingredientInput.unit
                )
                recipe.ingredients.append(ingredient)
            }

            // Add instructions
            for (index, instructionInput) in instructions.enumerated() {
                let instruction = Instruction(
                    stepNumber: index + 1,
                    instruction: instructionInput.instruction,
                    timeMinutes: Int(instructionInput.timeMinutes),
                    tip: instructionInput.tip.isEmpty ? nil : instructionInput.tip
                )
                recipe.instructions.append(instruction)
            }

            modelContext.insert(recipe)
        }

        dismiss()
    }
}

// MARK: - Input Models

struct IngredientInput {
    var item: String
    var quantity: String
    var unit: String

    var displayText: String {
        var text = ""
        if !quantity.isEmpty {
            text += quantity + " "
        }
        if !unit.isEmpty {
            text += unit + " "
        }
        text += item
        return text.trimmingCharacters(in: .whitespaces)
    }
}

struct InstructionInput {
    var instruction: String
    var timeMinutes: String
    var tip: String
}

// MARK: - Preview

#Preview {
    ManualRecipeFormView()
        .modelContainer(for: [Recipe.self], inMemory: true)
}
