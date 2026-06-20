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
            List {
                Section {
                    ConditionCheckInCard(entry: todayCondition) { showCheckIn = true }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(habits) { habit in
                        HabitRow(habit: habit, result: result(for: habit),
                                 streak: StreakCalculator.current(for: habit.id, in: results))
                    }
                    if habits.isEmpty {
                        Text("오른쪽 위 + 로 첫 습관을 추가해보세요.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    HStack {
                        Text("오늘의 습관")
                        Spacer()
                        Text("\(achievedCount) / \(habits.count) 달성").foregroundStyle(.secondary)
                    }
                }
                if let sentence = snapshots.first?.sentences.first {
                    Section {
                        Label(sentence, systemImage: "sparkles")
                            .font(.callout)
                    }
                }
            }
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
}
