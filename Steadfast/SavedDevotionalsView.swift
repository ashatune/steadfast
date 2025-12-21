import SwiftUI

struct SavedDevotionalsView: View {
    @EnvironmentObject private var savedStore: SavedDevotionalsStore

    var body: some View {
        Group {
            if savedStore.getAllSaved().isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.line)
                    Text("No saved devotionals yet")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Tap the bookmark on any devotional to save it here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg.ignoresSafeArea())
            } else {
                List {
                    ForEach(savedStore.getAllSaved()) { devotional in
                        NavigationLink {
                            DailyDevotionalDetailView(devotional: devotional)
                        } label: {
                            SavedDevotionalRow(devotional: devotional)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                savedStore.toggleSave(devotional: devotional)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .background(Theme.bg.ignoresSafeArea())
            }
        }
        .navigationTitle("Saved Devotionals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SavedDevotionalRow: View {
    let devotional: DailyDevotional

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(devotional.title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(devotional.verseReference)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            HStack {
                Text(dateString(devotional.date))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text(devotional.previewSnippet)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
