import SwiftUI

struct ConditionCheckInCard: View {
    let entry: ConditionEntry?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("오늘 컨디션").font(.subheadline.weight(.medium))
                    Spacer()
                    Text(entry == nil ? "기록하기" : "기록됨 · 수정")
                        .font(.caption).foregroundStyle(.secondary)
                }
                scaleRow(label: "기분", value: entry?.mood ?? 0)
                scaleRow(label: "에너지", value: entry?.energy ?? 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func scaleRow(label: String, value: Int) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.callout).foregroundStyle(.secondary).frame(width: 42, alignment: .leading)
            HStack(spacing: 7) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? Color.primary : Color.clear)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.secondary.opacity(0.5), lineWidth: i <= value ? 0 : 1))
                }
            }
        }
    }
}
