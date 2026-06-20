import SwiftUI

struct HabitRow: View {
    let habit: Habit
    let result: DailyResult?
    let streak: Int

    private var measuredText: String {
        guard let measured = result?.measured else { return "오늘 밤 판정 예정" }
        let m = habit.rule.metric
        let value = Int(measured.rounded())
        return "\(value)\(m.unit) / \(Int(habit.rule.target))\(m.unit)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.rule.metric.symbolName)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.body)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
        .padding(.vertical, 6)
    }

    private var subtitle: String {
        switch result?.status {
        case .achieved: return "\(measuredText) · 자동 확인됨"
        case .inProgress: return "\(measuredText) · 진행 중"
        case .missed: return "\(measuredText) · 미달"
        default: return habit.rule.comparison == .beforeTime ? "오늘 밤 판정 예정" : "대기"
        }
    }

    @ViewBuilder private var trailing: some View {
        HStack(spacing: 6) {
            if streak > 0 {
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.caption2).foregroundStyle(.orange).labelStyle(.titleAndIcon)
            }
            switch result?.status {
            case .achieved:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .inProgress:
                Text("\(percent)%").font(.caption).foregroundStyle(.orange)
            default:
                Text("대기").font(.caption2).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .overlay(Capsule().stroke(.secondary.opacity(0.4)))
            }
        }
    }

    private var percent: Int {
        guard let measured = result?.measured, habit.rule.target > 0 else { return 0 }
        return min(100, Int((measured / habit.rule.target * 100).rounded()))
    }

    private var statusColor: Color {
        switch result?.status {
        case .achieved: return .green
        case .inProgress: return .orange
        default: return .secondary
        }
    }
}
