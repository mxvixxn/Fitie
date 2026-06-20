import SwiftUI
import SwiftData

@main
struct FitieApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Habit.self, DailyResult.self,
                                        ConditionEntry.self, InsightSnapshot.self)
        SampleData.seedIfRequested(container)
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .modelContainer(container)
    }
}
