import SwiftUI
import SwiftData

struct ConditionCheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let day: Date
    let existing: ConditionEntry?

    @State private var mood = 3
    @State private var energy = 3
    @State private var note = ""
    @State private var saveTick = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    scaleCard(title: "기분", systemImage: "face.smiling",
                              value: $mood, color: Theme.mood,
                              low: "별로예요", high: "최고예요")
                    scaleCard(title: "에너지", systemImage: "bolt.fill",
                              value: $energy, color: Theme.achieved,
                              low: "지쳤어요", high: "활기차요")
                    VStack(alignment: .leading, spacing: 8) {
                        Label("메모", systemImage: "text.alignleft")
                            .font(.subheadline).fontWeight(.medium)
                        TextField("오늘 한 줄 (선택)", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                    }
                    .card()
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("오늘 컨디션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save).fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .sensoryFeedback(.selection, trigger: mood)
            .sensoryFeedback(.selection, trigger: energy)
            .sensoryFeedback(.success, trigger: saveTick)
            .onAppear {
                if let e = existing { mood = e.mood; energy = e.energy; note = e.note }
            }
        }
    }

    private func scaleCard(title: String, systemImage: String, value: Binding<Int>,
                           color: Color, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).foregroundStyle(color)
                Text(title).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text("\(value.wrappedValue) / 5").font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { i in
                    Button { value.wrappedValue = i } label: {
                        Circle()
                            .fill(i <= value.wrappedValue ? color : Color(.tertiarySystemFill))
                            .overlay(Text("\(i)").font(.footnote).fontWeight(.medium)
                                .foregroundStyle(i <= value.wrappedValue ? .white : .secondary))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Text(low); Spacer(); Text(high)
            }
            .font(.caption2).foregroundStyle(.secondary)
        }
        .card()
    }

    private func save() {
        let start = Calendar.current.startOfDay(for: day)
        if let e = existing {
            e.mood = mood; e.energy = energy; e.note = note
        } else {
            context.insert(ConditionEntry(day: start, mood: mood, energy: energy, note: note))
        }
        try? context.save()
        saveTick += 1
        dismiss()
    }
}
