import Foundation
import Testing
@testable import Fitie

struct InsightEngineTests {
    private let cal = Calendar(identifier: .gregorian)

    private func day(_ offset: Int) -> Date {
        cal.startOfDay(for: cal.date(byAdding: .day, value: offset, to: Date())!)
    }

    @Test func computesPositiveMoodDelta() {
        let habitID = UUID()
        var results: [DailyResult] = []
        var conditions: [ConditionEntry] = []
        for i in 0..<3 {
            results.append(DailyResult(habitID: habitID, day: day(-i), status: .achieved, measured: 100, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 5, energy: 3))
        }
        for i in 3..<6 {
            results.append(DailyResult(habitID: habitID, day: day(-i), status: .missed, measured: 0, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 2, energy: 3))
        }
        let insights = InsightEngine.insights(results: results, conditions: conditions,
                                              habitNames: [habitID: "걷기"])
        let mood = insights.first { $0.metric == .mood }
        #expect(mood != nil)
        #expect(mood?.delta == 3.0)
        #expect(mood?.sampleAchieved == 3)
        #expect(mood?.sampleOther == 3)
    }

    @Test func suppressesWhenSampleTooSmall() {
        let habitID = UUID()
        var results: [DailyResult] = []
        var conditions: [ConditionEntry] = []
        for i in 0..<2 {
            results.append(DailyResult(habitID: habitID, day: day(-i), status: .achieved, measured: 100, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 5, energy: 5))
        }
        for i in 2..<6 {
            results.append(DailyResult(habitID: habitID, day: day(-i), status: .missed, measured: 0, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 2, energy: 2))
        }
        let insights = InsightEngine.insights(results: results, conditions: conditions,
                                              habitNames: [habitID: "걷기"])
        #expect(insights.isEmpty)
    }

    @Test func ranksByAbsoluteDelta() {
        let a = UUID(); let b = UUID()
        var results: [DailyResult] = []
        var conditions: [ConditionEntry] = []
        for i in 0..<3 {
            results.append(DailyResult(habitID: a, day: day(-i), status: .achieved, measured: 1, source: .auto))
            results.append(DailyResult(habitID: b, day: day(-i), status: .achieved, measured: 1, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 4, energy: 3))
        }
        for i in 3..<6 {
            results.append(DailyResult(habitID: a, day: day(-i), status: .missed, measured: 0, source: .auto))
            results.append(DailyResult(habitID: b, day: day(-i), status: .missed, measured: 0, source: .auto))
            conditions.append(ConditionEntry(day: day(-i), mood: 3, energy: 3))
        }
        let insights = InsightEngine.insights(results: results, conditions: conditions,
                                              habitNames: [a: "A", b: "B"])
        #expect(insights.count >= 1)
        if insights.count >= 2 {
            #expect(abs(insights[0].delta) >= abs(insights[1].delta))
        }
    }
}
