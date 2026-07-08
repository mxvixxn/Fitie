import Foundation
import SwiftData

@MainActor
final class RefreshService {
    private let health: HealthDataSource
    private let phraser: InsightPhraser

    init(health: HealthDataSource, phraser: InsightPhraser) {
        self.health = health
        self.phraser = phraser
    }

    /// Evaluates every active habit for `day` and persists DailyResults.
    /// `dayIsOver: true` finalizes the day (pending/inProgress collapse to missed).
    func refresh(day: Date, dayIsOver: Bool, context: ModelContext) async throws {
        let day = Calendar.current.startOfDay(for: day)
        let habits = try context.fetch(FetchDescriptor<Habit>()).filter { !$0.isArchived }

        for habit in habits where habit.isActive(on: day) {
            let rule = habit.rule
            let existing = Store.dailyResult(context, habitID: habit.id, day: day)

            if rule.metric == .manual {
                // Manual habits are user-driven; refresh only closes out unchecked past days.
                if dayIsOver && existing?.status != .achieved {
                    Store.upsertDailyResult(context, habitID: habit.id, day: day,
                                            status: .missed, measured: existing?.measured,
                                            source: existing?.source ?? .manual)
                }
                continue
            }
            // Never overwrite a user's manual override with auto data.
            if existing?.source == .manual { continue }

            let measured = (try? await health.value(for: rule.metric, on: day)) ?? nil
            let status = HabitEvaluator.status(measured: measured, target: rule.target,
                                               comparison: rule.comparison, dayIsOver: dayIsOver)
            Store.upsertDailyResult(context, habitID: habit.id, day: day,
                                    status: status, measured: measured, source: .auto)
        }
        try? context.save()
    }

    /// Pulls today's health values while the day is still in progress.
    func refreshToday(context: ModelContext, now: Date = Date()) async throws {
        try await refresh(day: now, dayIsOver: false, context: context)
    }

    /// Recomputes insights over a rolling window and stores a snapshot.
    func recomputeInsights(context: ModelContext, windowDays: Int = 21, now: Date = Date()) async throws {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -windowDays, to: cal.startOfDay(for: now))!
        let results = try context.fetch(FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.day >= cutoff }))
        let conditions = try context.fetch(FetchDescriptor<ConditionEntry>(
            predicate: #Predicate { $0.day >= cutoff }))
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let names = Dictionary(habits.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })

        let insights = InsightEngine.insights(results: results, conditions: conditions, habitNames: names)
        var sentences: [String] = []
        for insight in insights { sentences.append(await phraser.phrase(insight)) }

        for old in try context.fetch(FetchDescriptor<InsightSnapshot>()) { context.delete(old) }
        context.insert(InsightSnapshot(generatedAt: now, sentences: sentences))
        try? context.save()
    }
}
