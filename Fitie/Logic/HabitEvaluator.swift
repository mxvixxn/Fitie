import Foundation

enum HabitEvaluator {
    static func status(measured: Double?, target: Double,
                       comparison: Comparison, dayIsOver: Bool) -> HabitStatus {
        switch comparison {
        case .atLeast:
            guard let measured else { return dayIsOver ? .missed : .pending }
            if measured >= target { return .achieved }
            if measured > 0 { return dayIsOver ? .missed : .inProgress }
            return dayIsOver ? .missed : .pending
        case .beforeTime:
            guard let measured else { return dayIsOver ? .missed : .pending }
            return measured <= target ? .achieved : .missed
        }
    }
}
