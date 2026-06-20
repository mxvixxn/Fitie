import SwiftUI
import SwiftData

@main
struct FitieApp: App {
    let container: ModelContainer = {
        try! ModelContainer(for: Habit.self, DailyResult.self, ConditionEntry.self, InsightSnapshot.self)
    }()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .modelContainer(container)
    }
}
