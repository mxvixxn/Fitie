import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @Query private var results: [DailyResult]
    @Query private var conditions: [ConditionEntry]
    @Query(sort: \InsightSnapshot.generatedAt, order: .reverse) private var snapshots: [InsightSnapshot]

    @State private var rangeDays = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    summaryCards
                    insightCard
                    trendCard
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("인사이트")
        }
    }

    // MARK: Summary metric cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            metric(value: completionText, label: "주간 달성률", systemImage: "checkmark.circle", color: Theme.achieved)
            metric(value: "\(longestStreak)일", label: "최장 스트릭", systemImage: "flame.fill", color: Theme.streak)
            metric(value: avgMoodText, label: "평균 기분", systemImage: "face.smiling", color: Theme.mood)
        }
    }

    private func metric(value: String, label: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage).font(.callout).foregroundStyle(color)
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: Insights

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주 인사이트").font(.headline)
            if let sentences = snapshots.first?.sentences, !sentences.isEmpty {
                ForEach(sentences, id: \.self) { s in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                        Text(s).font(.callout)
                    }
                }
            } else {
                Label("데이터가 더 모이면 인사이트를 보여드려요.", systemImage: "hourglass")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    // MARK: Trend chart

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("컨디션 추세").font(.headline)
                Spacer()
                Picker("기간", selection: $rangeDays) {
                    Text("7일").tag(7)
                    Text("30일").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            if trendData.isEmpty {
                Label("컨디션을 기록하면 추세가 보여요.", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(trendData) { c in
                    AreaMark(x: .value("날짜", c.day), y: .value("기분", c.mood))
                        .foregroundStyle(.linearGradient(colors: [Theme.mood.opacity(0.25), Theme.mood.opacity(0.02)],
                                                         startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("날짜", c.day), y: .value("기분", c.mood))
                        .foregroundStyle(by: .value("지표", "기분"))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("날짜", c.day), y: .value("에너지", c.energy))
                        .foregroundStyle(by: .value("지표", "에너지"))
                        .interpolationMethod(.catmullRom)
                }
                .chartForegroundStyleScale(["기분": Theme.mood, "에너지": Theme.achieved])
                .chartYScale(domain: 1...5)
                .chartYAxis { AxisMarks(values: [1, 3, 5]) }
                .frame(height: 200)
            }
        }
        .card()
    }

    // MARK: Derived data

    private struct TrendPoint: Identifiable {
        let id = UUID(); let day: Date; let mood: Int; let energy: Int
    }

    private func cutoff(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: Date()))!
    }

    private var trendData: [TrendPoint] {
        let start = cutoff(rangeDays)
        return conditions.filter { $0.day >= start }
            .sorted { $0.day < $1.day }
            .map { TrendPoint(day: $0.day, mood: $0.mood, energy: $0.energy) }
    }

    private var completionText: String {
        let start = cutoff(7)
        let recent = results.filter { $0.day >= start }
        guard !recent.isEmpty else { return "—" }
        let achieved = recent.filter { $0.status == .achieved }.count
        return "\(Int((Double(achieved) / Double(recent.count) * 100).rounded()))%"
    }

    private var longestStreak: Int {
        habits.map { StreakCalculator.longest(for: $0.id, in: results) }.max() ?? 0
    }

    private var avgMoodText: String {
        let start = cutoff(7)
        let recent = conditions.filter { $0.day >= start }
        guard !recent.isEmpty else { return "—" }
        let avg = Double(recent.map(\.mood).reduce(0, +)) / Double(recent.count)
        return String(format: "%.1f", avg)
    }
}
