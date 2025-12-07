# Culinara - iOS App Structure

## Overview
Culinara is a native iOS app built with Swift and SwiftUI that combines AI-powered recipe management with an intuitive cooking experience.

## Technology Stack
- **Swift 6.0+** - Primary language
- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern data persistence
- **Combine** - Reactive programming
- **Google Gemini API** - AI features (recipe generation, chat, substitutions)

## Project Structure

```
Culinara/
├── CulinaraApp.swift          # App entry point
├── ContentView.swift           # Main tab navigation
├── Models/
│   └── Recipe.swift           # SwiftData models (Recipe, Ingredient, Instruction, etc.)
├── Views/
│   ├── RecipeFeedView.swift   # Main recipe feed with filtering
│   ├── RecipeDetailView.swift # Recipe detail with ingredients & instructions
│   ├── CreateRecipeView.swift # Recipe creation hub
│   ├── AIGenerationView.swift # AI recipe generation from ingredients
│   ├── ChatView.swift         # Sous Chef AI chat
│   ├── SubstitutionView.swift # Magic ingredient substitution
│   ├── CollectionsView.swift  # Recipe collections management
│   └── SettingsView.swift     # App settings & API configuration
└── Services/
    └── GeminiService.swift    # Google Gemini API integration
```

## Screen Flow & User Journey

### 1. Recipe Feed (Home)
**File:** `RecipeFeedView.swift`

**Features:**
- Grid/list view of all recipes
- Filter chips for meal types (Breakfast, Lunch, Dinner, Dessert, Snack)
- Search functionality
- Empty state with call-to-action
- Pull to refresh

**Components:**
- `FilterChip` - Meal type filter buttons
- `RecipeCard` - Recipe preview card with image, title, time, servings
- `EmptyStateView` - Shown when no recipes exist

**Navigation:**
- Tap recipe card → RecipeDetailView
- Tap FAB (+) → CreateRecipeView

---

### 2. Recipe Detail
**File:** `RecipeDetailView.swift`

**Features:**
- Hero image
- Recipe metadata (time, servings, difficulty)
- Servings scaler (adjusts ingredient quantities dynamically)
- Ingredient checklist (tap to mark as gathered)
- Step-by-step instructions with timers
- Nutrition information (if available)
- Action buttons: Magic Sub, Chat, Share

**Components:**
- `MetaInfoItem` - Time, servings, difficulty indicators
- `IngredientRow` - Checkbox + ingredient + substitution button
- `InstructionRow` - Numbered steps with optional timers and tips
- `NutritionView` - Nutritional breakdown

**Actions:**
- "Magic Sub" → SubstitutionView
- "Chat" → ChatView
- "Share" → Native share sheet

---

### 3. Create Recipe Hub
**File:** `CreateRecipeView.swift`

**Features:**
- 4 creation methods presented as cards:
  1. **Generate with AI** → AIGenerationView
  2. **Manual Entry** → Manual form (to be implemented)
  3. **Import from URL** → URL scraper (to be implemented)
  4. **Scan Recipe** → OCR camera (to be implemented)

**Components:**
- `CreationMethodCard` - Gradient card for each creation method

**Navigation:**
- Tap "Generate with AI" → AIGenerationView
- Others → Future implementation

---

### 4. AI Recipe Generation
**File:** `AIGenerationView.swift`

**Features:**
- Multi-line ingredient input
- Visual ingredient chips (auto-parsed from text)
- Optional preferences:
  - Cuisine type (text input)
  - Difficulty (segmented picker)
  - Target cook time (slider, 15-120 min)
- Real-time generation with loading state
- Error handling with retry

**Flow:**
1. User enters ingredients (one per line)
2. Optionally sets preferences
3. Taps "Generate Recipe"
4. AI creates recipe via Gemini API
5. Recipe saved to SwiftData
6. Shows RecipeDetailView with generated recipe

**API Integration:**
- Uses `GeminiService.generateRecipe()`
- Model: `gemini-2.0-flash-exp`
- Returns fully structured Recipe object

---

### 5. Sous Chef Chat
**File:** `ChatView.swift`

**Features:**
- Context-aware AI chat about the recipe
- Suggested questions (if no history)
- Chat bubble UI (user right, AI left)
- Streaming responses (to be implemented)
- Message history preserved during session

**Suggested Questions:**
- "Can I make this ahead?"
- "What can I substitute?"
- "How do I know when it's done?"
- "Can I double this recipe?"

**Components:**
- `MessageBubble` - Chat message with timestamp
- `ChatMessage` - Message model (user/assistant)

**API Integration:**
- Uses `GeminiService.chatWithRecipe()`
- Maintains conversation context
- Recipe ingredients & instructions provided as context

---

### 6. Magic Substitution
**File:** `SubstitutionView.swift`

**Features:**
- Shows selected ingredient
- Dietary constraint chips (Vegan, Gluten-Free, Dairy-Free, etc.)
- AI-powered substitution suggestions
- Each substitution shows:
  - Alternative ingredient
  - Reason why it works
  - Category badge
  - "Use This" button (to be implemented)

**Constraints:**
- Vegan
- Vegetarian
- Gluten-Free
- Dairy-Free
- Nut-Free
- Kosher
- Halal

**Components:**
- `SubstitutionCard` - Alternative with reason & category
- `ConstraintChip` - Dietary filter chips
- `FlowLayout` - Custom layout for wrapping chips

**API Integration:**
- Uses `GeminiService.findSubstitutions()`
- Returns 3-5 alternatives per ingredient

---

### 7. Collections
**File:** `CollectionsView.swift`

**Features:**
- Grid of recipe collections
- Recipe count per collection
- Preview thumbnails (2x2 grid of recipe images)
- Create new collections
- Empty state

**Sub-Views:**
- `CollectionCard` - Collection preview with image grid
- `CreateCollectionView` - Form to create new collection
- `CollectionDetailView` - List of recipes in collection

**Data Model:**
- `Collection` - Name, description, array of recipes
- Many-to-many relationship with recipes

---

### 8. Settings
**File:** `SettingsView.swift`

**Features:**
- **API Configuration**
  - Gemini API key input
  - Status indicator (Set/Not Set)
  - Link to get API key (ai.google.dev)

- **Data Management**
  - Total recipe count
  - Export recipes (JSON)
  - Delete all recipes (destructive)

- **About**
  - App version
  - GitHub link
  - API documentation link

---

## Data Models (SwiftData)

### Recipe
```swift
@Model class Recipe {
    var id: UUID
    var title: String
    var description: String?
    var imageData: Data?
    var cookTime: Int
    var prepTime: Int
    var servings: Int
    var difficulty: Difficulty
    var cuisine: String?
    var mealType: MealType?
    var sourceType: SourceType
    var sourceURL: String?
    var ingredients: [Ingredient]
    var instructions: [Instruction]
    var nutrition: Nutrition?
    var tags: [Tag]
}
```

### Ingredient
```swift
@Model class Ingredient {
    var item: String
    var quantity: Double?
    var unit: String?
    var section: String?
    var isChecked: Bool
}
```

### Instruction
```swift
@Model class Instruction {
    var stepNumber: Int
    var instruction: String
    var timeMinutes: Int?
    var tip: String?
}
```

### Enums
- `Difficulty`: Easy, Medium, Hard
- `MealType`: Breakfast, Lunch, Dinner, Dessert, Snack
- `SourceType`: Original, AI Generated, Imported, OCR

---

## AI Features (Gemini Service)

### 1. Recipe Generation
**Endpoint:** `gemini-2.0-flash-exp`

**Input:**
- List of ingredients
- Optional: cuisine, difficulty, target cook time

**Output:**
- Complete Recipe object with:
  - Title & description
  - Ingredients (parsed with quantities & units)
  - Step-by-step instructions
  - Nutrition info
  - Suggested meal type

### 2. Chat (Sous Chef)
**Endpoint:** `gemini-2.0-flash-exp`

**Context Provided:**
- Recipe title, description
- Full ingredient list
- All instructions
- Previous conversation history

**Output:**
- Conversational responses about cooking techniques, timing, substitutions

### 3. Ingredient Substitution
**Endpoint:** `gemini-2.0-flash-exp`

**Input:**
- Ingredient name
- Dietary constraints (optional)

**Output:**
- 3-5 substitution options
- Each with alternative, reason, category

---

## Phase 1 Implementation Status

### ✅ Completed
- SwiftData models & schema
- All main screen views
- Navigation & routing
- Gemini API integration
- Recipe feed with filtering
- Recipe detail with servings scaling
- AI recipe generation
- Sous Chef chat
- Magic substitution
- Collections management
- Settings & API configuration

### 🔜 To Be Implemented
- Manual recipe entry form
- URL import scraper
- OCR cookbook scanner
- Camera integration for ingredients
- Image upload & storage
- Recipe editing
- Apply substitutions to recipe
- Export/import JSON
- iCloud sync (future)

---

## Running the Project

### Prerequisites
1. Xcode 16+ with iOS 17+ SDK
2. Google Gemini API key (get from: https://ai.google.dev)

### Setup
1. Open project in Xcode
2. Build and run on iOS Simulator or device
3. On first launch, go to Settings tab
4. Add your Gemini API key
5. Start creating recipes!

### Testing AI Features
1. Tap + button → "Generate with AI"
2. Enter ingredients (e.g., "chicken, rice, broccoli")
3. Optionally set preferences
4. Tap "Generate Recipe"
5. View generated recipe
6. Test "Chat" and "Magic Sub" features

---

## Design Philosophy

### iOS-Native Experience
- SwiftUI with native components
- System fonts and spacing
- SF Symbols for icons
- Haptic feedback (to be added)
- Native gestures and animations

### AI-First Approach
- AI generation is prominently featured
- Context-aware chat for cooking assistance
- Smart substitutions for dietary needs
- Future: ingredient recognition, recipe analysis

### Local-First (Phase 1)
- All data stored in SwiftData
- No authentication required
- No backend dependencies
- Works completely offline (except AI features)

---

## Future Enhancements (Phase 2)

- User authentication (Apple Sign-In, Google)
- Cloud sync via Supabase
- Social features (share recipes, follow users)
- Recipe ratings and comments
- Meal planning calendar
- Shopping list generation
- Voice commands for hands-free cooking
- Apple Watch companion app
- Widget support
- Siri Shortcuts integration

---

## License
MIT License

## Contributors
Built with Claude Code
