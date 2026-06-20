import SwiftUI

struct HabitRow: View {
    let habit: Habit
    let result: DailyResult?
    let streak: Int

    private var metricColor: Color { Theme.metricColor(habit.rule.metric) }

    private var measuredText: String {
        guard let measured = result?.measured else { return "오늘 밤 판정 예정" }
        let m = habit.rule.metric
        let value = Int(measured.rounded())
        return "\(value)\(m.unit) / \(Int(habit.rule.target))\(m.unit)"
    }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: habit.rule.metric.symbolName)
                .font(.system(size: 19))
                .frame(width: 40, height: 40)
                .background(metricColor.opacity(0.18))
                .foregroundStyle(metricColor)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.body).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.name), \(subtitle)")
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
        HStack(spacing: 8) {
            if streak > 0 {
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.caption2).foregroundStyle(Theme.streak).labelStyle(.titleAndIcon)
            }
            switch result?.status {
            case .achieved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3).foregroundStyle(Theme.achieved)
            case .inProgress:
                Text("\(percent)%").font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Theme.inProgress)
            default:
                Text("대기").font(.caption2).foregroundStyle(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var percent: Int {
        guard let measured = result?.measured, habit.rule.target > 0 else { return 0 }
        return min(100, Int((measured / habit.rule.target * 100).rounded()))
    }
}
