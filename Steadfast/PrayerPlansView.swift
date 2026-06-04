import SwiftUI

struct PrayerPlansView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var durationPlan: PrayerPlan? = nil
    @State private var exercisePlan: PrayerPlan? = nil
    @State private var selectedDuration: MeditationDurationOption?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.library.prayerPlans) { plan in
                        Button {
                            durationPlan = plan
                        } label: {
                            PrayerPlanCard(plan: plan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Prayer Plans")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $exercisePlan) { plan in
                PrayerPlanDetail(plan: plan, breathingDuration: selectedDuration)
            }
            .sheet(item: $durationPlan) { plan in
                MeditationDurationPickerSheet(
                    title: plan.title,
                    prompt: "How long would you like timed breathing steps to last?",
                    selectedDuration: selectedDuration ?? MeditationDurationOption.default
                ) { duration in
                    selectedDuration = duration
                    durationPlan = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        exercisePlan = plan
                    }
                }
                .presentationDetents([.height(430), .medium])
                .presentationDragIndicator(.visible)
            }
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
    }
}

// Card row for a plan
struct PrayerPlanCard: View {
    let plan: PrayerPlan

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "hands.sparkles.fill")
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title).font(.headline).foregroundStyle(Theme.cardTitle)
                Text("\(plan.steps.count) steps")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.line)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}
