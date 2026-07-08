import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.createdAt)
    private var habits: [Habit]
    @Query private var results: [DailyResult]
    @Query private var conditions: [ConditionEntry]
    @Query(sort: \InsightSnapshot.generatedAt, order: .reverse) private var snapshots: [InsightSnapshot]

    @State private var showCheckIn = false
    @State private var showAddHabit = false
    @State private var editingHabit: Habit?
    @State private var session = SessionController()
    @State private var deleteTick = 0
    @State private var showConfetti = false
    @State private var celebrated = false
    @State private var path = NavigationPath()
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
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    summaryHeader
                    ConditionCheckInCard(entry: todayCondition) { showCheckIn = true }
                    habitsSection
                    insightTeaser
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("오늘")
            .toolbar { toolbarContent }
            .navigationDestination(for: UUID.self) { id in
                if let habit = habits.first(where: { $0.id == id }) {
                    HabitDetailView(habit: habit)
                }
            }
            .sheet(isPresented: $showCheckIn) {
                ConditionCheckInSheet(day: today, existing: todayCondition)
            }
            .sheet(isPresented: $showAddHabit) { HabitEditSheet() }
            .sheet(item: $editingHabit) { habit in HabitEditSheet(habit: habit) }
            .sensoryFeedback(.impact(weight: .light), trigger: deleteTick)
            .sensoryFeedback(.success, trigger: showConfetti)
            .overlay(alignment: .top) {
                if showConfetti { ConfettiView().padding(.top, 90) }
            }
            .onChange(of: achievedCount) { _, newValue in
                if !habits.isEmpty && newValue == habits.count {
                    if !celebrated {
                        celebrated = true
                        showConfetti = true
                        Task { try? await Task.sleep(for: .seconds(2)); showConfetti = false }
                    }
                } else {
                    celebrated = false
                }
            }
            .onAppear {
                if ProcessInfo.processInfo.environment["FITIE_DETAIL"] == "1",
                   path.isEmpty, let first = habits.first {
                    path.append(first.id)
                }
            }
            .refreshable { await refresher.run() }
        }
    }

    // MARK: Header

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후예요"
        default: return "좋은 저녁이에요"
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting).font(.title3).fontWeight(.bold)
                Text(today.formatted(.dateTime.month().day().weekday(.wide)
                    .locale(Locale(identifier: "ko_KR"))))
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                if habits.isEmpty {
                    Text("습관을 추가해 시작하세요").font(.footnote).foregroundStyle(.secondary)
                } else if achievedCount == habits.count {
                    Label("오늘 목표 달성!", systemImage: "checkmark.seal.fill")
                        .font(.subheadline).fontWeight(.medium).foregroundStyle(Theme.achieved)
                        .symbolEffect(.bounce, value: achievedCount)
                } else {
                    Text("\(habits.count - achievedCount)개 남았어요")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            DailyRing(achieved: achievedCount, total: habits.count)
        }
        .card()
    }

    // MARK: Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("오늘의 습관").font(.headline)
                Spacer()
                if !habits.isEmpty {
                    Text("\(achievedCount) / \(habits.count) 달성")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            if habits.isEmpty { emptyHabits } else { habitsCard }
        }
    }

    private var habitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                NavigationLink(value: habit.id) {
                    HabitRow(habit: habit, result: result(for: habit),
                             streak: StreakCalculator.current(for: habit.id, in: results))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button { editingHabit = habit } label: { Label("편집", systemImage: "pencil") }
                    Button(role: .destructive) { delete(habit) } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                if index < habits.count - 1 { Divider() }
            }
        }
        .card()
    }

    private var emptyHabits: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 34)).foregroundStyle(Theme.accent)
            Text("첫 습관을 추가해보세요").font(.headline)
            Text("걷기·물·운동 같은 습관을 만들면\nApple 건강이 자동으로 채워줘요.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showAddHabit = true } label: {
                Label("습관 추가", systemImage: "plus")
            }
            .buttonStyle(.glassProminent)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .card()
    }

    // MARK: Insight

    @ViewBuilder private var insightTeaser: some View {
        if let sentence = snapshots.first?.sentences.first {
            Button(action: onShowInsights) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    Text(sentence).font(.callout).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .card()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                if session.isRunning { session.stop() } else { session.start(habitName: "걷기", goalMinutes: 10) }
            } label: {
                Label(session.isRunning ? "세션 종료" : "걷기 세션",
                      systemImage: session.isRunning ? "stop.circle" : "figure.walk")
            }
            .sensoryFeedback(.impact, trigger: session.isRunning)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAddHabit = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("습관 추가")
        }
    }

    private func delete(_ habit: Habit) {
        NotificationService.cancelReminder(habitID: habit.id)
        withAnimation { context.delete(habit) }
        try? context.save()
        deleteTick += 1
    }
}
