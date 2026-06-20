import SwiftUI
import SwiftData

@main
struct FitieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Habit.self, DailyResult.self, ConditionEntry.self, InsightSnapshot.self])
    }
}
