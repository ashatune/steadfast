import SwiftUI

// VerseOfDayStrip.swift
struct VerseOfDayStrip: View {
    let verse: Verse

    @State private var showDurationPicker = false
    @State private var selectedDuration: MeditationDurationOption?
    @State private var showAnchorExercise = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anchor of the Day")
                .font(.title3)
                .bold()
                .foregroundStyle(Theme.sectionTitle)

            Button {
                showDurationPicker = true
            } label: {
                VerseCard(verse: verse, isFlatStyle: true)
            }
            .buttonStyle(.plain)
            .background(
                NavigationLink("", isActive: $showAnchorExercise) {
                    AnchorBreathView(
                        verse: verse,
                        totalDuration: selectedDuration?.seconds ?? MeditationDurationOption.default.seconds,
                        inhaleSecs: 4,
                        holdSecs: 4,
                        exhaleSecs: 6
                    )
                }
                .hidden()
            )
        }
        // ❌ No extra background/padding wrapper — keeps the page uniform
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showDurationPicker) {
            MeditationDurationPickerSheet(
                title: "Anchor of the Day",
                prompt: "How long would you like to breathe with today’s verse?",
                selectedDuration: selectedDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedDuration = duration
                showDurationPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showAnchorExercise = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
    }
}
