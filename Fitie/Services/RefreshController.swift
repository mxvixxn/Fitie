import Foundation
import SwiftData

@MainActor
final class RefreshController {
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
        try? await service.refreshToday(context: context)
        try? await service.recomputeInsights(context: context)
    }
}
