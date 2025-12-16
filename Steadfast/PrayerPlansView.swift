import SwiftUI

struct PrayerPlansView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.library.prayerPlans) { plan in
                        NavigationLink { PrayerPlanDetail(plan: plan) } label: {
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
                Text(plan.title).font(.headline)
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
