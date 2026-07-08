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
    @State private var colorHex = Theme.palette[5]
    @State private var weekdays: Set<Int> = []
    @State private var saveTick = 0

    private static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

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

                Section {
                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            let isOn = weekdays.contains(day)
                            Button {
                                if isOn { weekdays.remove(day) } else { weekdays.insert(day) }
                            } label: {
                                Text(Self.weekdaySymbols[day - 1])
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(isOn ? Theme.accent : Color(.tertiarySystemFill), in: .circle)
                                    .foregroundStyle(isOn ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("반복")
                } footer: {
                    Text(weekdays.isEmpty || weekdays.count == 7 ? "매일 반복해요."
                         : "선택한 요일에만 반복해요.")
                }

                Section("색상") {
                    HStack(spacing: 14) {
                        ForEach(Theme.palette, id: \.self) { hex in
                            Circle()
                                .fill(Theme.paletteColor(hex))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay(Circle().strokeBorder(.primary.opacity(hex == colorHex ? 0.25 : 0),
                                                               lineWidth: 2))
                                .onTapGesture { colorHex = hex }
                                .accessibilityLabel("색상")
                                .accessibilityAddTraits(hex == colorHex ? [.isSelected] : [])
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
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
        case .manual: return 1
        }
    }

    private func prefill() {
        guard let habit else { return }
        name = habit.name
        let rule = habit.rule
        metric = rule.metric
        target = rule.metric == .sleepStart ? rule.target / 60 : rule.target
        colorHex = habit.colorHex.isEmpty ? Theme.palette[5] : habit.colorHex
        weekdays = Set(habit.activeWeekdays)
        if let h = habit.reminderHour, let m = habit.reminderMinute {
            reminderOn = true
            reminderTime = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        }
    }

    private func save() {
        let storedTarget = metric == .sleepStart ? target * 60 : target
        let rule = VerificationRule(metric: metric, target: storedTarget)
        let target = habit ?? Habit(name: name, emoji: "", colorHex: colorHex, rule: rule)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.colorHex = colorHex
        target.rule = rule
        target.activeWeekdays = (weekdays.isEmpty || weekdays.count == 7) ? [] : weekdays.sorted()

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

        let habitID = target.id, habitName = target.name
        if reminderOn, let h = target.reminderHour, let m = target.reminderMinute {
            Task {
                await NotificationService.requestAuthorization()
                await NotificationService.rearmReminder(habitID: habitID, name: habitName,
                                                        hour: h, minute: m, skipToday: false)
            }
        } else {
            Task { await NotificationService.cancelReminder(habitID: habitID) }
        }
        saveTick += 1
        dismiss()
    }

    private func deleteHabit() {
        guard let habit else { return }
        Task { await NotificationService.cancelReminder(habitID: habit.id) }
        context.delete(habit)
        try? context.save()
        dismiss()
    }
}
