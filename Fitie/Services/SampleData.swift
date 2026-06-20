import Foundation
import SwiftData

/// Dev-only demo data. Runs ONLY when the app is launched with the environment
/// variable FITIE_SEED=1, so it never affects real users.
enum SampleData {
    static var isSeedMode: Bool { ProcessInfo.processInfo.environment["FITIE_SEED"] == "1" }

    @MainActor
    static func seedIfRequested(_ container: ModelContainer) {
        guard isSeedMode else { return }
        let context = container.mainContext
        guard ((try? context.fetch(FetchDescriptor<Habit>())) ?? []).isEmpty else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func day(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: today)! }

        let walk = Habit(name: "걷기", emoji: "🚶", colorHex: "#4FB58E",
                         rule: VerificationRule(metric: .steps, target: 6000))
        let water = Habit(name: "물 마시기", emoji: "💧", colorHex: "#4E92C9",
                          rule: VerificationRule(metric: .water, target: 8))
        let workout = Habit(name: "운동", emoji: "🏋️", colorHex: "#D08A5E",
                            rule: VerificationRule(metric: .exerciseMinutes, target: 20))
        let sleep = Habit(name: "일찍 자기", emoji: "🌙", colorHex: "#8E84C9",
                          rule: VerificationRule(metric: .sleepStart, target: 23 * 60))
        [walk, water, workout, sleep].forEach { context.insert($0) }

        // Today's snapshot — mixed states to show the design language.
        context.insert(DailyResult(habitID: walk.id, day: today, status: .achieved, measured: 7200, source: .auto))
        context.insert(DailyResult(habitID: water.id, day: today, status: .inProgress, measured: 5, source: .auto))
        context.insert(DailyResult(habitID: workout.id, day: today, status: .achieved, measured: 32, source: .auto))
        context.insert(DailyResult(habitID: sleep.id, day: today, status: .pending, measured: nil, source: .auto))

        // History so the insight engine + chart have something to show.
        for d in 1...12 {
            let walked = d % 3 != 0
            context.insert(DailyResult(habitID: walk.id, day: day(d),
                                       status: walked ? .achieved : .missed,
                                       measured: walked ? 6500 : 1200, source: .auto))
            let mood = walked ? Int.random(in: 4...5) : Int.random(in: 2...3)
            let energy = walked ? Int.random(in: 3...5) : Int.random(in: 2...3)
            context.insert(ConditionEntry(day: day(d), mood: mood, energy: energy))
        }
        context.insert(ConditionEntry(day: today, mood: 4, energy: 3))
        try? context.save()
    }
}
