import Foundation
import SwiftData

@MainActor
final class RefreshController {
    private static let lastFinalizedKey = "lastFinalizedDay"

    private let container: ModelContainer
    private let health: HealthDataSource
    private let phraser: InsightPhraser

    init(container: ModelContainer, health: HealthDataSource, phraser: InsightPhraser) {
        self.container = container
        self.health = health
        self.phraser = phraser
    }

    func run() async {
        let context = container.mainContext
        let service = RefreshService(health: health, phraser: phraser)
        // In seed/demo mode, keep the seeded "today" snapshot instead of overwriting
        // it from HealthKit (which is empty on a fresh Simulator).
        if !SampleData.isSeedMode {
            let defaults = UserDefaults.standard
            let anchor = defaults.object(forKey: Self.lastFinalizedKey) as? Date
            if let finalized = (try? await service.finalizePastDays(
                    context: context, lastFinalizedDay: anchor)) ?? nil {
                defaults.set(finalized, forKey: Self.lastFinalizedKey)
            }
            try? await service.refreshToday(context: context)
        }
        try? await service.recomputeInsights(context: context)
    }
}
