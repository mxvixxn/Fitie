import Foundation
import SwiftData

enum Store {
    static let schema = Schema([Habit.self, DailyResult.self, ConditionEntry.self, InsightSnapshot.self])

    @MainActor
    static func inMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }

    static func upsertDailyResult(_ context: ModelContext, habitID: UUID, day: Date,
                                  status: HabitStatus, measured: Double?, source: ResultSource) {
        let start = Calendar.current.startOfDay(for: day)
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.habitID == habitID && $0.day == start }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.status = status
            existing.measured = measured
            existing.source = source
        } else {
            context.insert(DailyResult(habitID: habitID, day: start, status: status,
                                       measured: measured, source: source))
        }
    }
}
