import Foundation

enum HealthMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case steps
    case exerciseMinutes
    case water
    case mindfulMinutes
    case sleepStart

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "걷기"
        case .exerciseMinutes: return "운동"
        case .water: return "물 마시기"
        case .mindfulMinutes: return "마음챙김"
        case .sleepStart: return "일찍 자기"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "보"
        case .exerciseMinutes, .mindfulMinutes: return "분"
        case .water: return "잔"
        case .sleepStart: return "시"
        }
    }

    var defaultComparison: Comparison {
        self == .sleepStart ? .beforeTime : .atLeast
    }

    var symbolName: String {
        switch self {
        case .steps: return "figure.walk"
        case .exerciseMinutes: return "figure.run"
        case .water: return "drop.fill"
        case .mindfulMinutes: return "brain.head.profile"
        case .sleepStart: return "moon.fill"
        }
    }

    var verificationHint: String {
        switch self {
        case .steps: return "Apple 건강의 걸음 수로 자동 확인돼요."
        case .exerciseMinutes: return "Apple 건강의 운동 시간으로 자동 확인돼요."
        case .water: return "Apple 건강에 기록한 물 섭취량으로 확인돼요."
        case .mindfulMinutes: return "Apple 건강의 마음챙김 기록으로 확인돼요."
        case .sleepStart: return "수면 데이터의 취침 시각으로 확인돼요."
        }
    }
}

enum Comparison: String, Codable, Sendable {
    case atLeast
    case beforeTime
}
