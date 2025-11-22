import Foundation
import SwiftData

@MainActor
class GeminiService: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }

    // MARK: - Recipe Generation

    func generateRecipe(
        ingredients: [String],
        cuisine: String?,
        difficulty: Difficulty,
        targetCookTime: Int
    ) async throws -> Recipe {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let prompt = buildRecipeGenerationPrompt(
            ingredients: ingredients,
            cuisine: cuisine,
            difficulty: difficulty,
            targetCookTime: targetCookTime
        )

        let response = try await makeRequest(prompt: prompt, model: "gemini-2.0-flash-exp")
        let recipe = try parseRecipeResponse(response, ingredients: ingredients)

        return recipe
    }

    // MARK: - Chat

    func chatWithRecipe(
        recipe: Recipe,
        question: String,
        history: [ChatMessage]
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let context = buildRecipeContext(recipe)
        let prompt = """
        Recipe Context:
        \(context)

        Previous conversation:
        \(history.map { "\($0.role == .user ? "User" : "Assistant"): \($0.content)" }.joined(separator: "\n"))

        User Question: \(question)

        Please provide a helpful, concise answer about this recipe. Be practical and friendly.
        """

        let response = try await makeRequest(prompt: prompt, model: "gemini-2.0-flash-exp")
        return extractTextFromResponse(response)
    }

    // MARK: - Substitutions

    func findSubstitutions(
        for ingredient: String,
        constraints: [String]
    ) async throws -> [Substitution] {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let prompt = buildSubstitutionPrompt(ingredient: ingredient, constraints: constraints)
        let response = try await makeRequest(prompt: prompt, model: "gemini-2.0-flash-exp")

        return try parseSubstitutionsResponse(response, original: ingredient)
    }

    // MARK: - Private Methods

    private func makeRequest(prompt: String, model: String) async throws -> [String: Any] {
        let urlString = "\(baseURL)/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.invalidResponse
        }

        return json
    }

    private func extractTextFromResponse(_ json: [String: Any]) -> String {
        guard let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return "Unable to generate response"
        }

        return text
    }

    // MARK: - Prompt Builders

    private func buildRecipeGenerationPrompt(
        ingredients: [String],
        cuisine: String?,
        difficulty: Difficulty,
        targetCookTime: Int
    ) -> String {
        """
        You are a professional chef. Generate a delicious recipe using these ingredients: \(ingredients.joined(separator: ", ")).

        Requirements:
        \(cuisine != nil ? "- Cuisine: \(cuisine!)" : "")
        - Difficulty: \(difficulty.rawValue)
        - Target cooking time: around \(targetCookTime) minutes

        Return ONLY valid JSON with this exact structure (no markdown, no explanation):
        {
          "title": "Recipe Name",
          "description": "Brief 1-2 sentence description",
          "cookTime": 30,
          "prepTime": 15,
          "servings": 4,
          "cuisine": "cuisine type or null",
          "mealType": "Breakfast, Lunch, Dinner, Dessert, or Snack",
          "ingredients": [
            {"item": "ingredient name", "quantity": 1.0, "unit": "cup", "section": "Main"},
            {"item": "ingredient name", "quantity": null, "unit": null, "section": null}
          ],
          "instructions": [
            {"stepNumber": 1, "instruction": "detailed step", "timeMinutes": 5, "tip": "helpful tip or null"}
          ],
          "nutrition": {
            "calories": 400,
            "proteinG": 25.0,
            "carbsG": 30.0,
            "fatG": 15.0
          }
        }

        Make it creative and delicious!
        """
    }

    private func buildRecipeContext(_ recipe: Recipe) -> String {
        """
        Title: \(recipe.title)
        \(recipe.recipeDescription ?? "")

        Ingredients:
        \(recipe.ingredients.map { "- \($0.displayText)" }.joined(separator: "\n"))

        Instructions:
        \(recipe.instructions.sorted(by: { $0.stepNumber < $1.stepNumber })
            .map { "\($0.stepNumber). \($0.instruction)" }
            .joined(separator: "\n"))
        """
    }

    private func buildSubstitutionPrompt(ingredient: String, constraints: [String]) -> String {
        """
        Find 3-5 substitutions for: \(ingredient)

        \(constraints.isEmpty ? "" : "Dietary constraints: \(constraints.joined(separator: ", "))")

        Return ONLY valid JSON array (no markdown, no explanation):
        [
          {
            "alternative": "substitute name",
            "reason": "why this works (1-2 sentences)",
            "category": "Vegan, Kosher, Allergy, Preference, or Availability"
          }
        ]

        Focus on practical, accessible substitutes.
        """
    }

    // MARK: - Response Parsers

    private func parseRecipeResponse(_ json: [String: Any], ingredients: [String]) throws -> Recipe {
        let text = extractTextFromResponse(json)

        // Extract JSON from response
        guard let jsonData = text.data(using: .utf8),
              let recipeData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.parsingError
        }

        // Parse recipe
        let recipe = Recipe(
            title: recipeData["title"] as? String ?? "Untitled Recipe",
            description: recipeData["description"] as? String,
            cookTime: recipeData["cookTime"] as? Int ?? 30,
            prepTime: recipeData["prepTime"] as? Int ?? 15,
            servings: recipeData["servings"] as? Int ?? 4,
            difficulty: .medium,
            cuisine: recipeData["cuisine"] as? String,
            mealType: parseMealType(recipeData["mealType"] as? String),
            sourceType: .aiGenerated
        )

        // Parse ingredients
        if let ingredientsData = recipeData["ingredients"] as? [[String: Any]] {
            for ingData in ingredientsData {
                let ingredient = Ingredient(
                    item: ingData["item"] as? String ?? "",
                    quantity: ingData["quantity"] as? Double,
                    unit: ingData["unit"] as? String,
                    section: ingData["section"] as? String
                )
                recipe.ingredients.append(ingredient)
            }
        }

        // Parse instructions
        if let instructionsData = recipeData["instructions"] as? [[String: Any]] {
            for (index, instData) in instructionsData.enumerated() {
                let instruction = Instruction(
                    stepNumber: index + 1,
                    instruction: instData["instruction"] as? String ?? "",
                    timeMinutes: instData["timeMinutes"] as? Int,
                    tip: instData["tip"] as? String
                )
                recipe.instructions.append(instruction)
            }
        }

        // Parse nutrition (optional)
        if let nutritionData = recipeData["nutrition"] as? [String: Any] {
            let nutrition = Nutrition(
                calories: nutritionData["calories"] as? Int ?? 0,
                proteinG: nutritionData["proteinG"] as? Double ?? 0,
                carbsG: nutritionData["carbsG"] as? Double ?? 0,
                fatG: nutritionData["fatG"] as? Double ?? 0
            )
            recipe.nutrition = nutrition
        }

        return recipe
    }

    private func parseSubstitutionsResponse(_ json: [String: Any], original: String) throws -> [Substitution] {
        let text = extractTextFromResponse(json)

        guard let jsonData = text.data(using: .utf8),
              let substitutionsData = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw GeminiError.parsingError
        }

        return substitutionsData.map { data in
            Substitution(
                original: original,
                alternative: data["alternative"] as? String ?? "",
                reason: data["reason"] as? String ?? "",
                category: parseSubstitutionCategory(data["category"] as? String)
            )
        }
    }

    private func parseMealType(_ string: String?) -> MealType? {
        guard let string = string else { return nil }
        return MealType.allCases.first { $0.rawValue.lowercased() == string.lowercased() }
    }

    private func parseSubstitutionCategory(_ string: String?) -> SubstitutionCategory {
        guard let string = string else { return .preference }
        return SubstitutionCategory(rawValue: string) ?? .preference
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please add your Gemini API key in Settings"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}
