# Culinara - React Native + Expo

AI-powered recipe management app built with React Native, Expo, Supabase, SuperWall, and RevenueCat.

## 🚀 Tech Stack

- **React Native** - Cross-platform mobile framework
- **Expo** - Development platform for React Native
- **TypeScript** - Type-safe JavaScript
- **Supabase** - Backend as a Service (Auth, Database, Storage)
- **RevenueCat** - In-app purchase and subscription management
- **SuperWall** - Paywall and monetization platform
- **React Navigation** - Routing and navigation

## 📁 Project Structure

```
Culinara/
├── src/
│   ├── components/       # Reusable UI components
│   ├── screens/          # App screens
│   ├── services/         # API and business logic
│   ├── hooks/            # Custom React hooks
│   ├── utils/            # Utility functions
│   ├── types/            # TypeScript type definitions
│   ├── config/           # Configuration files (Supabase, RevenueCat, SuperWall)
│   └── navigation/       # Navigation setup
├── assets/               # Images, fonts, etc.
├── swift-reference/      # Original Swift/SwiftUI implementation (for reference)
├── docs/                 # Documentation
├── App.tsx               # Root component
├── app.json              # Expo configuration
└── package.json          # Dependencies

```

## 🛠️ Setup

### Prerequisites

- Node.js 18+ and npm
- Expo CLI: `npm install -g expo-cli`
- iOS Simulator (Mac) or Android Studio (for Android development)
- Expo Go app on your phone (for quick testing)

### Installation

1. **Clone and install dependencies:**

```bash
npm install
```

2. **Set up environment variables:**

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Then fill in your credentials:

```env
# Supabase Configuration
EXPO_PUBLIC_SUPABASE_URL=your_supabase_project_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# RevenueCat Configuration
EXPO_PUBLIC_REVENUECAT_API_KEY=your_revenuecat_api_key

# SuperWall Configuration
EXPO_PUBLIC_SUPERWALL_API_KEY=your_superwall_api_key
```

### Getting API Keys

#### Supabase
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Go to Settings → API
4. Copy the Project URL and anon/public key

#### RevenueCat
1. Go to [revenuecat.com](https://www.revenuecat.com)
2. Create an account and project
3. Go to API keys and copy your public SDK key

#### SuperWall
1. Go to [superwall.com](https://superwall.com)
2. Create an account and project
3. Copy your API key from the dashboard

## 🏃 Running the App

```bash
# Start Expo development server
npm start

# Run on iOS simulator (Mac only)
npm run ios

# Run on Android emulator
npm run android

# Run on web
npm run web
```

You can also scan the QR code with the Expo Go app on your phone to test on a real device.

## 📦 Key Dependencies

### Core
- `expo` - Expo framework
- `react-native` - React Native framework
- `typescript` - Type safety

### Backend & Auth
- `@supabase/supabase-js` - Supabase client
- `@react-native-async-storage/async-storage` - Persistent storage
- `react-native-url-polyfill` - URL polyfill for React Native

### Monetization
- `react-native-purchases` - RevenueCat SDK
- `@superwall/react-native-superwall` - SuperWall SDK

### Navigation
- `@react-navigation/native` - Navigation library
- `@react-navigation/stack` - Stack navigator
- `react-native-screens` - Native screen optimization
- `react-native-safe-area-context` - Safe area handling

## 🗄️ Database Schema (Supabase)

You'll need to set up the following tables in Supabase:

### Users
Handled automatically by Supabase Auth.

### Recipes
```sql
create table recipes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  description text,
  image_url text,
  cook_time integer not null,
  prep_time integer not null,
  servings integer not null,
  difficulty text check (difficulty in ('easy', 'medium', 'hard')),
  cuisine text,
  meal_type text check (meal_type in ('breakfast', 'lunch', 'dinner', 'dessert', 'snack')),
  source_type text check (source_type in ('original', 'ai_generated', 'imported', 'ocr')),
  source_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### Ingredients
```sql
create table ingredients (
  id uuid default uuid_generate_v4() primary key,
  recipe_id uuid references recipes on delete cascade not null,
  item text not null,
  quantity decimal,
  unit text,
  section text,
  "order" integer not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### Instructions
```sql
create table instructions (
  id uuid default uuid_generate_v4() primary key,
  recipe_id uuid references recipes on delete cascade not null,
  step_number integer not null,
  instruction text not null,
  time_minutes integer,
  tip text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### Collections
```sql
create table collections (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table collection_recipes (
  collection_id uuid references collections on delete cascade,
  recipe_id uuid references recipes on delete cascade,
  added_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (collection_id, recipe_id)
);
```

## 🔐 Row Level Security (RLS)

Enable RLS on all tables and add policies:

```sql
-- Enable RLS
alter table recipes enable row level security;
alter table ingredients enable row level security;
alter table instructions enable row level security;
alter table collections enable row level security;
alter table collection_recipes enable row level security;

-- Recipes policies
create policy "Users can view their own recipes"
  on recipes for select
  using (auth.uid() = user_id);

create policy "Users can insert their own recipes"
  on recipes for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own recipes"
  on recipes for update
  using (auth.uid() = user_id);

create policy "Users can delete their own recipes"
  on recipes for delete
  using (auth.uid() = user_id);

-- Similar policies for other tables...
```

## 🎨 Features to Implement

Based on the Swift implementation, here are the key features to build:

### Phase 1: Core Features
- [ ] Authentication (Sign up, Sign in, Password reset)
- [ ] Recipe feed with filtering and search
- [ ] Recipe detail view with servings scaling
- [ ] Recipe creation (Manual entry)
- [ ] Collections management
- [ ] Settings screen

### Phase 2: AI Features
- [ ] AI recipe generation (using Google Gemini or OpenAI)
- [ ] Sous Chef chat assistant
- [ ] Magic ingredient substitution
- [ ] Recipe import from URL
- [ ] OCR for cookbook scanning

### Phase 3: Advanced Features
- [ ] Cloud sync across devices
- [ ] Social features (share recipes)
- [ ] Meal planning calendar
- [ ] Shopping list generation
- [ ] Nutrition tracking
- [ ] Recipe ratings and comments

### Phase 4: Monetization
- [ ] Premium subscription with RevenueCat
- [ ] Paywall integration with SuperWall
- [ ] Premium features gating
- [ ] Usage analytics

## 📱 Swift Reference

The original Swift/SwiftUI implementation is preserved in the `swift-reference/` folder for reference. You can refer to:

- `swift-reference/Culinara/Views/` - UI screens
- `swift-reference/Culinara/Models/` - Data models
- `swift-reference/Culinara/Services/` - API services
- `docs/PROJECT_STRUCTURE.md` - Detailed Swift app documentation

## 🤝 Contributing

This is a personal project, but feel free to fork and adapt it for your needs!

## 📄 License

MIT License

## 🙏 Acknowledgments

Built with React Native, Expo, Supabase, RevenueCat, and SuperWall.
Original Swift implementation migrated to React Native for cross-platform support.
