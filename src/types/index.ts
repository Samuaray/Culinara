// Database types will be generated from Supabase
export interface Database {
  public: {
    Tables: {
      // Add your table types here
    };
  };
}

// User types
export interface User {
  id: string;
  email?: string;
  created_at: string;
  updated_at: string;
}

// Recipe types (based on your Swift app structure)
export interface Recipe {
  id: string;
  title: string;
  description?: string;
  image_url?: string;
  cook_time: number;
  prep_time: number;
  servings: number;
  difficulty: 'easy' | 'medium' | 'hard';
  cuisine?: string;
  meal_type?: 'breakfast' | 'lunch' | 'dinner' | 'dessert' | 'snack';
  source_type: 'original' | 'ai_generated' | 'imported' | 'ocr';
  source_url?: string;
  user_id: string;
  created_at: string;
  updated_at: string;
}

export interface Ingredient {
  id: string;
  recipe_id: string;
  item: string;
  quantity?: number;
  unit?: string;
  section?: string;
  order: number;
}

export interface Instruction {
  id: string;
  recipe_id: string;
  step_number: number;
  instruction: string;
  time_minutes?: number;
  tip?: string;
}

export interface Nutrition {
  id: string;
  recipe_id: string;
  calories?: number;
  protein?: number;
  carbohydrates?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
}

// Collection types
export interface Collection {
  id: string;
  user_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface CollectionRecipe {
  collection_id: string;
  recipe_id: string;
  added_at: string;
}
