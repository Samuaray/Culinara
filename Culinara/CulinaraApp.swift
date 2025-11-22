import SwiftUI
import SwiftData

@main
struct CulinaraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Recipe.self, Collection.self])
    }
}
