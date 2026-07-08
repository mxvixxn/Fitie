import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    @Query private var allResults: [DailyResult]
    @State private var showEdit = false

    private let cal = Calendar.current

    private var results: [DailyResult] { allResults.filter { $0.habitID == habit.id } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                statsRow
                heatmapCard
                if habit.rule.comparison == .atLeast { recentChartCard }
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("편집") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { HabitEditSheet(habit: habit) }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: habit.rule.metric.symbolName)
                .font(.system(size: 24))
                .frame(width: 54, height: 54)
                .background(habit.tintColor.opacity(0.15))
                .foregroundStyle(habit.tintColor)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name).font(.title3).fontWeight(.semibold)
                Text(ruleDescription).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .card()
    }

    private var ruleDescription: String {
        let r = habit.rule
        switch r.comparison {
        case .atLeast:
            return "매일 · \(Int(r.target))\(r.metric.unit) 이상"
        case .beforeTime:
            let h = Int(r.target) / 60, m = Int(r.target) % 60
            return String(format: "매일 · %02d:%02d 이전 취침", h, m)
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat("\(StreakCalculator.current(for: habit.id, in: allResults))일", "현재 스트릭", "flame.fill", habit.tintColor)
            stat("\(StreakCalculator.longest(for: habit.id, in: allResults))일", "최장 스트릭", "trophy.fill", Theme.streak)
            stat(completion30, "30일 달성률", "checkmark.circle", Theme.achieved)
        }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).font(.callout).foregroundStyle(color)
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var completion30: String {
        let start = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: Date()))!
        let recent = results.filter { $0.day >= start }
        guard !recent.isEmpty else { return "—" }
        let achieved = recent.filter { $0.status == .achieved }.count
        return "\(Int((Double(achieved) / Double(recent.count) * 100).rounded()))%"
    }

    // MARK: Heatmap

    private var heatmapDays: [Date] {
        let today = cal.startOfDay(for: Date())
        return (0..<35).reversed().map { cal.date(byAdding: .day, value: -$0, to: today)! }
    }

    private func status(on day: Date) -> HabitStatus? {
        results.first { cal.isDate($0.day, inSameDayAs: day) }?.status
    }

    private func cellColor(_ status: HabitStatus?) -> Color {
        switch status {
        case .achieved: return habit.tintColor
        case .inProgress: return habit.tintColor.opacity(0.45)
        case .missed: return Color(.systemFill)
        default: return Color(.quaternarySystemFill)
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 35일").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(heatmapDays, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(cellColor(status(on: day)))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: 12) {
                legend(habit.tintColor, "달성")
                legend(Color(.systemFill), "미달")
                legend(Color(.quaternarySystemFill), "기록 없음")
            }
            .font(.caption2).foregroundStyle(.secondary)
        }
        .card()
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 11, height: 11)
            Text(label)
        }
    }

    // MARK: Recent chart

    private struct DayValue: Identifiable { let id = UUID(); let day: Date; let value: Double }

    private var recent14: [DayValue] {
        let today = cal.startOfDay(for: Date())
        return (0..<14).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let measured = results.first { cal.isDate($0.day, inSameDayAs: day) }?.measured ?? 0
            return DayValue(day: day, value: measured)
        }
    }

    private var recentChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 14일 \(habit.rule.metric.unit)").font(.headline)
            Chart {
                ForEach(recent14) { p in
                    BarMark(x: .value("날짜", p.day, unit: .day),
                            y: .value("값", p.value))
                        .foregroundStyle(habit.tintColor.gradient)
                        .cornerRadius(4)
                }
                RuleMark(y: .value("목표", habit.rule.target))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("목표").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            .frame(height: 170)
        }
        .card()
    }
}
