import SwiftUI

enum PeaceReminderSelection: String, CaseIterable, Identifiable {
    case morning
    case midday
    case evening
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        case .custom: return "Custom"
        }
    }

    var timeLabel: String? {
        switch self {
        case .morning: return "8:00 AM"
        case .midday: return "12:30 PM"
        case .evening: return "7:00 PM"
        case .custom: return nil
        }
    }

    var date: Date {
        let components = timeComponents(customTime: Date())
        return Calendar.current.date(
            bySettingHour: components.hour ?? 8,
            minute: components.minute ?? 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    func timeComponents(customTime: Date) -> DateComponents {
        switch self {
        case .morning: return DateComponents(hour: 8, minute: 0)
        case .midday: return DateComponents(hour: 12, minute: 30)
        case .evening: return DateComponents(hour: 19, minute: 0)
        case .custom:
            return Calendar.current.dateComponents([.hour, .minute], from: customTime)
        }
    }
}

struct PeacePracticeOnboardingSlide: View {
    @Binding var selection: PeaceReminderSelection
    @Binding var customTime: Date
    let isActive: Bool
    @State private var isShowingCustomTimeSheet = false
    @State private var pendingCustomTime = Date()
    @State private var selectionBeforeCustomSheet: PeaceReminderSelection = .morning
    @State private var hasCommittedCustomTime = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ViewThatFits(in: .vertical) {
            slideContent

            ScrollView {
                slideContent
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isShowingCustomTimeSheet) {
            customTimeSheet
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
    }

    private var slideContent: some View {
        VStack(spacing: 10) {
                ThirtyDayPeacePath(isActive: isActive)
                    .frame(height: 130)
                    .padding(.horizontal, 4)

                Text("YOUR 30-DAY PEACE PRACTICE")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.accent)

                Text("Small moments create steadier days")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(OnboardingPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Build a more peaceful rhythm with 5 minutes of prayer, breathing, or reflection each day.")
                    .font(.body)
                    .foregroundStyle(OnboardingPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Choose your daily reminder")
                    .font(.headline)
                    .foregroundStyle(OnboardingPalette.primaryText)
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(PeaceReminderSelection.allCases) { option in
                        reminderOption(option)
                    }
                }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
    }

    private func reminderOption(_ option: PeaceReminderSelection) -> some View {
        let isSelected = selection == option
        return Button {
            if option == .custom {
                selectionBeforeCustomSheet = selection
                pendingCustomTime = customTime
                isShowingCustomTimeSheet = true
            } else {
                selection = option
            }
        } label: {
            VStack(spacing: 2) {
                Text(option.title)
                    .font(.subheadline.weight(.semibold))
                Text(optionTimeLabel(option))
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Theme.accent : OnboardingPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isSelected ? OnboardingPalette.selectedCardFill : OnboardingPalette.cardFill,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.accent : OnboardingPalette.subtleStroke, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: option))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func optionTimeLabel(_ option: PeaceReminderSelection) -> String {
        if option == .custom {
            return hasCommittedCustomTime || selection == .custom ? formattedCustomTime : "Choose a time"
        }
        return option.timeLabel ?? ""
    }

    private func accessibilityLabel(for option: PeaceReminderSelection) -> String {
        switch option {
        case .morning: return "Morning reminder, 8:00 AM"
        case .midday: return "Midday reminder, 12:30 PM"
        case .evening: return "Evening reminder, 7:00 PM"
        case .custom:
            return hasCommittedCustomTime || selection == .custom
                ? "Custom reminder, \(formattedCustomTime)"
                : "Custom reminder time"
        }
    }

    private var formattedCustomTime: String {
        customTime.formatted(date: .omitted, time: .shortened)
    }

    private var customTimeSheet: some View {
        NavigationStack {
            VStack(spacing: 8) {
                DatePicker(
                    "Choose your reminder time",
                    selection: $pendingCustomTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .accessibilityLabel("Reminder time")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnboardingPalette.pageBackground.ignoresSafeArea())
            .navigationTitle("Choose your reminder time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selection = selectionBeforeCustomSheet
                        isShowingCustomTimeSheet = false
                    }
                    .accessibilityLabel("Cancel custom reminder time")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        customTime = pendingCustomTime
                        hasCommittedCustomTime = true
                        selection = .custom
                        isShowingCustomTimeSheet = false
                    }
                    .fontWeight(.bold)
                    .tint(Theme.accent)
                    .accessibilityLabel("Done choosing reminder time")
                }
            }
        }
    }
}

private struct ThirtyDayPeacePath: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var illuminateDots = false
    @State private var revealMilestones = false
    @State private var hasAnimated = false

    private let milestones = [0, 6, 13, 20, 29]
    private let labels = ["Day 1", "Day 7", "Day 14", "Day 21", "Day 30"]
    private let symbols = ["circle.circle", "heart.fill", "hands.sparkles.fill", "checkmark.circle.fill"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PeacePracticePath()
                    .stroke(Theme.accent.opacity(0.15), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                PeacePracticePath()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [Theme.accent2, Theme.accent], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )

                ForEach(0..<30, id: \.self) { index in
                    let point = PeacePracticePath.point(for: index, in: geometry.size)
                    Circle()
                        .fill(illuminateDots ? Theme.accent : OnboardingPalette.controlFill)
                        .frame(width: milestones.contains(index) ? 10 : 6, height: milestones.contains(index) ? 10 : 6)
                        .overlay(Circle().stroke(OnboardingPalette.pageBackground, lineWidth: 2))
                        .position(point)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.18).delay(Double(index) * 0.04),
                            value: illuminateDots
                        )
                        .accessibilityHidden(true)
                }

                ForEach(Array(milestones.enumerated()), id: \.element) { milestoneIndex, dayIndex in
                    let point = PeacePracticePath.point(for: dayIndex, in: geometry.size)
                    VStack(spacing: 2) {
                        if milestoneIndex > 0 {
                            Image(systemName: symbols[milestoneIndex - 1])
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        Text(labels[milestoneIndex])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(OnboardingPalette.secondaryText)
                    }
                    .position(x: point.x, y: point.y + (milestoneIndex.isMultiple(of: 2) ? 25 : -23))
                    .opacity(revealMilestones ? 1 : 0)
                    .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A 30-day path illustrating the growth of a consistent five-minute daily peace practice.")
        .onAppear {
            if isActive { animateOnce() }
        }
        .onChange(of: isActive) { active in
            if active { animateOnce() }
        }
    }

    private func animateOnce() {
        guard !hasAnimated else { return }
        hasAnimated = true
        if reduceMotion {
            progress = 1
            illuminateDots = true
            revealMilestones = true
        } else {
            withAnimation(.easeInOut(duration: 1.5)) { progress = 1 }
            illuminateDots = true
            withAnimation(.easeOut(duration: 0.45).delay(1.05)) { revealMilestones = true }
        }
    }
}

private struct PeacePracticePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Self.point(at: 0, in: rect.size))
        path.addCurve(
            to: Self.point(at: 1, in: rect.size),
            control1: CGPoint(x: rect.width * 0.30, y: rect.height * 0.82),
            control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.20)
        )
        return path
    }

    static func point(for index: Int, in size: CGSize) -> CGPoint {
        point(at: CGFloat(index) / 29, in: size)
    }

    private static func point(at progress: CGFloat, in size: CGSize) -> CGPoint {
        let start = CGPoint(x: size.width * 0.06, y: size.height * 0.76)
        let control1 = CGPoint(x: size.width * 0.30, y: size.height * 0.82)
        let control2 = CGPoint(x: size.width * 0.65, y: size.height * 0.20)
        let end = CGPoint(x: size.width * 0.94, y: size.height * 0.24)
        let inverse = 1 - progress
        return CGPoint(
            x: inverse * inverse * inverse * start.x
                + 3 * inverse * inverse * progress * control1.x
                + 3 * inverse * progress * progress * control2.x
                + progress * progress * progress * end.x,
            y: inverse * inverse * inverse * start.y
                + 3 * inverse * inverse * progress * control1.y
                + 3 * inverse * progress * progress * control2.y
                + progress * progress * progress * end.y
        )
    }
}
