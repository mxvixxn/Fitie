import SwiftUI
import SwiftData

struct HabitEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var habit: Habit?   // nil = create new

    @State private var name = ""
    @State private var metric: HealthMetric = .steps
    @State private var target: Double = 5000
    @State private var reminderOn = false
    @State private var reminderTime = Date()
    @State private var saveTick = 0

    private var isEditing: Bool { habit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("습관") {
                    TextField("이름 (예: 아침 산책)", text: $name)
                        .font(.body)
                }

                Section {
                    Picker("종류", selection: $metric) {
                        ForEach(HealthMetric.allCases) { m in
                            Label(m.displayName, systemImage: m.symbolName).tag(m)
                        }
                    }
                    .onChange(of: metric) { _, new in
                        if !isEditing { target = Self.defaultTarget(for: new) }
                    }
                    HStack {
                        Text(metric == .sleepStart ? "취침 시각" : "하루 목표")
                        Spacer()
                        TextField("목표", value: $target, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text(metric.unit).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("자동 판정")
                } footer: {
                    Label(metric.verificationHint, systemImage: "checkmark.seal")
                        .font(.caption)
                }

                Section("리마인더") {
                    Toggle("알림", isOn: $reminderOn.animation())
                    if reminderOn {
                        DatePicker("시간", selection: $reminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive, action: deleteHabit) {
                            Label("습관 삭제", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .fontDesign(.rounded)
            .tint(Theme.accent)
            .navigationTitle(isEditing ? "습관 편집" : "새 습관")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "저장" : "추가", action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .sensoryFeedback(.success, trigger: saveTick)
            .onAppear(perform: prefill)
        }
    }

    private static func defaultTarget(for m: HealthMetric) -> Double {
        switch m {
        case .steps: return 5000
        case .exerciseMinutes: return 20
        case .water: return 8
        case .mindfulMinutes: return 10
        case .sleepStart: return 23
        }
    }

    private func prefill() {
        guard let habit else { return }
        name = habit.name
        let rule = habit.rule
        metric = rule.metric
        target = rule.metric == .sleepStart ? rule.target / 60 : rule.target
        if let h = habit.reminderHour, let m = habit.reminderMinute {
            reminderOn = true
            reminderTime = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        }
    }

    private func save() {
        let storedTarget = metric == .sleepStart ? target * 60 : target
        let rule = VerificationRule(metric: metric, target: storedTarget)
        let target = habit ?? Habit(name: name, emoji: "", colorHex: "#5B6BB5", rule: rule)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.rule = rule

        if reminderOn {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            target.reminderHour = comps.hour
            target.reminderMinute = comps.minute
        } else {
            target.reminderHour = nil
            target.reminderMinute = nil
        }

        if habit == nil { context.insert(target) }
        try? context.save()

        NotificationService.cancelReminder(habitID: target.id)
        if reminderOn, let h = target.reminderHour, let m = target.reminderMinute {
            Task {
                await NotificationService.requestAuthorization()
                NotificationService.scheduleReminder(habitID: target.id, name: target.name, hour: h, minute: m)
            }
        }
        saveTick += 1
        dismiss()
    }

    private func deleteHabit() {
        guard let habit else { return }
        NotificationService.cancelReminder(habitID: habit.id)
        context.delete(habit)
        try? context.save()
        dismiss()
    }
}
