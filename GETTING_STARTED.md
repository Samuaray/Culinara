# Getting Started with Culinara (React Native + Expo)

This guide will help you get the Culinara app up and running.

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys (you can start without them for basic development):

```env
EXPO_PUBLIC_SUPABASE_URL=your_supabase_project_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
EXPO_PUBLIC_REVENUECAT_API_KEY=your_revenuecat_api_key
EXPO_PUBLIC_SUPERWALL_API_KEY=your_superwall_api_key
```

### 3. Run the App

```bash
# Start the Expo development server
npm start
```

This will open the Expo Dev Tools in your browser. From there you can:

- Press `i` to open in iOS Simulator (Mac only)
- Press `a` to open in Android Emulator
- Press `w` to open in web browser
- Scan QR code with Expo Go app on your phone

## Development Without API Keys

The app is designed to gracefully handle missing API keys during development:

- **Without Supabase**: Auth features will be disabled, but you can still build UI
- **Without RevenueCat**: Purchase features will log warnings but won't crash
- **Without SuperWall**: Paywall features will be disabled

You can develop most of the UI and functionality without setting up external services initially.

## Recommended Development Flow

### Phase 1: UI Development (No API keys needed)
1. Build out the screen components in `src/screens/`
2. Create reusable UI components in `src/components/`
3. Set up navigation in `src/navigation/`
4. Test on Expo Go or simulators

### Phase 2: Backend Integration
1. Set up Supabase project and get API keys
2. Create database tables (see README.md for SQL schema)
3. Implement authentication
4. Connect screens to Supabase data

### Phase 3: Monetization
1. Set up RevenueCat project
2. Configure subscription products
3. Set up SuperWall paywalls
4. Integrate purchase flows

## File Structure Overview

```
src/
├── components/     # Put reusable UI components here
├── screens/        # Put screen components here (RecipeFeed, RecipeDetail, etc.)
├── navigation/     # Navigation setup with React Navigation
├── services/       # API calls and business logic
├── hooks/          # Custom React hooks (useAuth, useRecipes, etc.)
├── config/         # Configuration files (already set up!)
├── types/          # TypeScript types (already set up!)
└── utils/          # Helper functions
```

## Building Your First Screen

1. Create a new screen in `src/screens/`:

```tsx
// src/screens/RecipeFeedScreen.tsx
import { View, Text, StyleSheet } from 'react-native';

export const RecipeFeedScreen = () => {
  return (
    <View style={styles.container}>
      <Text>Recipe Feed</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
});
```

2. Set up navigation (coming next!)

## Swift Reference

If you're migrating features from the Swift app, check:
- `swift-reference/Culinara/Views/` for UI screens
- `docs/PROJECT_STRUCTURE.md` for detailed documentation

## Troubleshooting

### Metro bundler issues
```bash
# Clear cache
npx expo start -c
```

### iOS build issues (Mac)
```bash
cd ios
pod install
cd ..
```

### Android build issues
```bash
cd android
./gradlew clean
cd ..
```

### Module resolution issues
```bash
# Delete node_modules and reinstall
rm -rf node_modules
npm install
```

## Next Steps

1. Set up navigation (React Navigation is already installed)
2. Create your first screen
3. Connect to Supabase (optional initially)
4. Build out the features!

Check `README.md` for the complete feature roadmap and database schema.

Happy coding! 🚀
