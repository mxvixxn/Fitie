import Testing
@testable import Fitie

struct HabitEvaluatorTests {
    @Test func atLeast_reachedTarget_isAchieved() {
        let s = HabitEvaluator.status(measured: 12, target: 10, comparison: .atLeast, dayIsOver: false)
        #expect(s == .achieved)
    }

    @Test func atLeast_partialDuringDay_isInProgress() {
        let s = HabitEvaluator.status(measured: 4, target: 10, comparison: .atLeast, dayIsOver: false)
        #expect(s == .inProgress)
    }

    @Test func atLeast_zeroDuringDay_isPending() {
        let s = HabitEvaluator.status(measured: 0, target: 10, comparison: .atLeast, dayIsOver: false)
        #expect(s == .pending)
    }

    @Test func atLeast_noDataDuringDay_isPending() {
        let s = HabitEvaluator.status(measured: nil, target: 10, comparison: .atLeast, dayIsOver: false)
        #expect(s == .pending)
    }

    @Test func atLeast_belowTargetAfterDay_isMissed() {
        let s = HabitEvaluator.status(measured: 4, target: 10, comparison: .atLeast, dayIsOver: true)
        #expect(s == .missed)
    }

    @Test func atLeast_noDataAfterDay_isMissed() {
        let s = HabitEvaluator.status(measured: nil, target: 10, comparison: .atLeast, dayIsOver: true)
        #expect(s == .missed)
    }

    @Test func beforeTime_onsetBeforeTarget_isAchieved() {
        // target 23:00 -> 1380 minutes; onset 22:30 -> 1350
        let s = HabitEvaluator.status(measured: 1350, target: 1380, comparison: .beforeTime, dayIsOver: false)
        #expect(s == .achieved)
    }

    @Test func beforeTime_onsetAfterTarget_isMissed() {
        let s = HabitEvaluator.status(measured: 1400, target: 1380, comparison: .beforeTime, dayIsOver: false)
        #expect(s == .missed)
    }

    @Test func beforeTime_noOnsetDuringDay_isPending() {
        let s = HabitEvaluator.status(measured: nil, target: 1380, comparison: .beforeTime, dayIsOver: false)
        #expect(s == .pending)
    }
}
