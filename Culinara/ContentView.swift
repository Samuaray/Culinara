import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showCreateRecipe = false

    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeFeedView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating Action Button
            if selectedTab == 0 {
                Button {
                    showCreateRecipe = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue, in: Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
        .sheet(isPresented: $showCreateRecipe) {
            CreateRecipeView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Collection.self], inMemory: true)
}
