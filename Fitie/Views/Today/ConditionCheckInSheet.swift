import SwiftUI
import SwiftData

struct ConditionCheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let day: Date
    let existing: ConditionEntry?

    @State private var mood: Double = 3
    @State private var energy: Double = 3
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("기분") {
                    Slider(value: $mood, in: 1...5, step: 1)
                    Text("\(Int(mood)) / 5").foregroundStyle(.secondary)
                }
                Section("에너지") {
                    Slider(value: $energy, in: 1...5, step: 1)
                    Text("\(Int(energy)) / 5").foregroundStyle(.secondary)
                }
                Section("메모") {
                    TextField("한 줄 메모 (선택)", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("오늘 컨디션")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .onAppear {
                if let e = existing {
                    mood = Double(e.mood); energy = Double(e.energy); note = e.note
                }
            }
        }
    }

    private func save() {
        let start = Calendar.current.startOfDay(for: day)
        if let e = existing {
            e.mood = Int(mood); e.energy = Int(energy); e.note = note
        } else {
            context.insert(ConditionEntry(day: start, mood: Int(mood), energy: Int(energy), note: note))
        }
        try? context.save()
        dismiss()
    }
}
