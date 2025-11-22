import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var title: String
    var recipeDescription: String?
    var imageData: Data?
    var cookTime: Int
    var prepTime: Int
    var servings: Int
    var difficulty: Difficulty
    var cuisine: String?
    var mealType: MealType?
    var sourceType: SourceType
    var sourceURL: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade) var instructions: [Instruction]
    @Relationship var nutrition: Nutrition?
    @Relationship var tags: [Tag]

    init(
        title: String,
        description: String? = nil,
        cookTime: Int = 30,
        prepTime: Int = 15,
        servings: Int = 4,
        difficulty: Difficulty = .medium,
        cuisine: String? = nil,
        mealType: MealType? = nil,
        sourceType: SourceType = .original,
        sourceURL: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.recipeDescription = description
        self.cookTime = cookTime
        self.prepTime = prepTime
        self.servings = servings
        self.difficulty = difficulty
        self.cuisine = cuisine
        self.mealType = mealType
        self.sourceType = sourceType
        self.sourceURL = sourceURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.ingredients = []
        self.instructions = []
    }

    var totalTime: Int {
        prepTime + cookTime
    }
}

@Model
final class Ingredient {
    var id: UUID
    var item: String
    var quantity: Double?
    var unit: String?
    var section: String?
    var isChecked: Bool
    var recipe: Recipe?

    init(item: String, quantity: Double? = nil, unit: String? = nil, section: String? = nil) {
        self.id = UUID()
        self.item = item
        self.quantity = quantity
        self.unit = unit
        self.section = section
        self.isChecked = false
    }

    var displayText: String {
        var text = ""
        if let quantity = quantity {
            text += "\(quantity) "
        }
        if let unit = unit {
            text += "\(unit) "
        }
        text += item
        return text.trimmingCharacters(in: .whitespaces)
    }
}

@Model
final class Instruction {
    var id: UUID
    var stepNumber: Int
    var instruction: String
    var timeMinutes: Int?
    var tip: String?
    var recipe: Recipe?

    init(stepNumber: Int, instruction: String, timeMinutes: Int? = nil, tip: String? = nil) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.timeMinutes = timeMinutes
        self.tip = tip
    }
}

@Model
final class Nutrition {
    var id: UUID
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double?
    var sugarG: Double?
    var sodiumMg: Double?
    var recipe: Recipe?

    init(calories: Int, proteinG: Double, carbsG: Double, fatG: Double) {
        self.id = UUID()
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

@Model
final class Tag {
    var id: UUID
    var name: String
    var category: String
    var recipes: [Recipe]

    init(name: String, category: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.recipes = []
    }
}

@Model
final class Collection {
    var id: UUID
    var name: String
    var collectionDescription: String?
    var createdAt: Date
    var recipes: [Recipe]

    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.collectionDescription = description
        self.createdAt = Date()
        self.recipes = []
    }
}

// MARK: - Enums

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

enum SourceType: String, Codable, CaseIterable {
    case original = "Original"
    case aiGenerated = "AI Generated"
    case imported = "Imported"
    case ocr = "OCR"
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case dessert = "Dessert"
    case snack = "Snack"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .dessert: return "birthday.cake.fill"
        case .snack: return "leaf.fill"
        }
    }
}
