import SwiftUI
import SwiftData

@main
struct GoldTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Portfolio.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color("BrandGold"))
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 960, height: 680)
        #endif
    }
}
