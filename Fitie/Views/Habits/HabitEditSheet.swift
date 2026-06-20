import SwiftUI
import SwiftData

struct HabitEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "🚶"
    @State private var metric: HealthMetric = .steps
    @State private var target: Double = 5000
    @State private var reminderOn = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("습관") {
                    TextField("이름", text: $name)
                    TextField("이모지", text: $emoji)
                }
                Section("자동 판정") {
                    Picker("종류", selection: $metric) {
                        ForEach(HealthMetric.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .onChange(of: metric) { _, newValue in
                        target = defaultTarget(for: newValue)
                    }
                    HStack {
                        Text(metric == .sleepStart ? "취침 시각(시)" : "목표")
                        Spacer()
                        TextField("목표", value: $target, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        Text(metric.unit).foregroundStyle(.secondary)
                    }
                }
                Section("리마인더") {
                    Toggle("알림", isOn: $reminderOn)
                    if reminderOn {
                        DatePicker("시간", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .fontDesign(.rounded)
            .tint(Theme.accent)
            .navigationTitle("새 습관")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") { save() }.disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func defaultTarget(for m: HealthMetric) -> Double {
        switch m {
        case .steps: return 5000
        case .exerciseMinutes: return 20
        case .water: return 8
        case .mindfulMinutes: return 10
        case .sleepStart: return 23
        }
    }

    private func save() {
        // For sleepStart, target is an hour -> convert to minutes-from-midnight.
        let storedTarget = metric == .sleepStart ? target * 60 : target
        let rule = VerificationRule(metric: metric, target: storedTarget)
        let habit = Habit(name: name, emoji: emoji, colorHex: "#1D9E75", rule: rule)
        if reminderOn {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            habit.reminderHour = comps.hour
            habit.reminderMinute = comps.minute
        }
        context.insert(habit)
        try? context.save()

        if reminderOn, let hour = habit.reminderHour, let minute = habit.reminderMinute {
            Task {
                await NotificationService.requestAuthorization()
                NotificationService.scheduleReminder(habitID: habit.id, name: habit.name,
                                                      hour: hour, minute: minute)
            }
        }
        dismiss()
    }
}
