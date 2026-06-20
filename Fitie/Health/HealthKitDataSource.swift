import Foundation
import HealthKit

final class HealthKitDataSource: HealthDataSource, @unchecked Sendable {
    private let store = HKHealthStore()

    private func readTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.dietaryWater),
            HKCategoryType(.sleepAnalysis),
        ]
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes())
    }

    func value(for metric: HealthMetric, on day: Date) async throws -> Double? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        switch metric {
        case .steps:
            return try await sum(.stepCount, unit: .count(), predicate: predicate)
        case .water:
            return try await sum(.dietaryWater, unit: .literUnit(with: .milli), predicate: predicate)
                .map { $0 / 200.0 }   // ~200ml per glass
        case .exerciseMinutes:
            return try await sum(.appleExerciseTime, unit: .minute(), predicate: predicate)
        case .mindfulMinutes:
            return try await mindfulMinutes(predicate: predicate)
        case .sleepStart:
            return try await sleepOnsetMinutes(start: start, end: end)
        }
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit,
                     predicate: NSPredicate) async throws -> Double? {
        let type = HKQuantityType(id)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func mindfulMinutes(predicate: NSPredicate) async throws -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return nil }
        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let minutes = (samples ?? []).reduce(0.0) { acc, s in
                    acc + s.endDate.timeIntervalSince(s.startDate) / 60.0
                }
                cont.resume(returning: minutes == 0 ? nil : minutes)
            }
            store.execute(q)
        }
    }

    private func sleepOnsetMinutes(start: Date, end: Date) async throws -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let asleep = (samples as? [HKCategorySample])?.first { s in
                    HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue).contains(s.value)
                }
                guard let onset = asleep?.startDate else { cont.resume(returning: nil); return }
                let cal = Calendar.current
                let minutes = Double(cal.component(.hour, from: onset) * 60 + cal.component(.minute, from: onset))
                cont.resume(returning: minutes)
            }
            store.execute(q)
        }
    }
}
