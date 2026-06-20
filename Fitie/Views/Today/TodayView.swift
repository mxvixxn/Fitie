import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt)
    private var habits: [Habit]
    @Query private var results: [DailyResult]
    @Query private var conditions: [ConditionEntry]
    @Query(sort: \InsightSnapshot.generatedAt, order: .reverse) private var snapshots: [InsightSnapshot]

    @State private var showCheckIn = false
    @State private var showAddHabit = false
    @State private var session = SessionController()
    let refresher: RefreshController
    let onShowInsights: () -> Void

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var todayCondition: ConditionEntry? {
        conditions.first { Calendar.current.isDate($0.day, inSameDayAs: today) }
    }
    private func result(for habit: Habit) -> DailyResult? {
        results.first { $0.habitID == habit.id && Calendar.current.isDate($0.day, inSameDayAs: today) }
    }
    private var achievedCount: Int {
        habits.filter { result(for: $0)?.status == .achieved }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConditionCheckInCard(entry: todayCondition) { showCheckIn = true }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("오늘의 습관").font(.headline)
                            Spacer()
                            Text("\(achievedCount) / \(habits.count) 달성")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)

                        habitsCard
                    }

                    if let sentence = snapshots.first?.sentences.first {
                        Button(action: onShowInsights) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                                Text(sentence).font(.callout).foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.footnote).foregroundStyle(Theme.accent)
                            }
                            .glassCard(cornerRadius: 22, tint: Theme.mood.opacity(0.25))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("오늘")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(session.isRunning ? "세션 종료" : "걷기 세션") {
                        if session.isRunning { session.stop() }
                        else { session.start(habitName: "걷기", goalMinutes: 10) }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddHabit = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showCheckIn) {
                ConditionCheckInSheet(day: today, existing: todayCondition)
            }
            .sheet(isPresented: $showAddHabit) { HabitEditSheet() }
            .task { await refresher.run() }
            .refreshable { await refresher.run() }
        }
    }

    @ViewBuilder private var habitsCard: some View {
        Group {
            if habits.isEmpty {
                Text("오른쪽 위 + 로 첫 습관을 추가해보세요.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                        HabitRow(habit: habit, result: result(for: habit),
                                 streak: StreakCalculator.current(for: habit.id, in: results))
                        if index < habits.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
        .glassCard()
    }
}
