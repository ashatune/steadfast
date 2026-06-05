// PrayersView.swift
import SwiftUI

struct PrayersView: View {
    @EnvironmentObject private var vm: AppViewModel

    private let hSpacing: CGFloat = 16
    private let vSpacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 16
    private let cardAspectRatio: CGFloat = 1.18

    private let meditations = PrayerMeditationLibrary.all

    @State private var showQuickStartDurations = false
    @State private var selectedQuickStartDuration: MeditationDurationOption?
    @State private var showQuickStartSession = false

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - (horizontalPadding * 2)
            let columnWidth = floor((available - hSpacing) / 2)
            let cardHeight = columnWidth / cardAspectRatio
            let cardSize = CGSize(width: columnWidth, height: cardHeight)

            // 🔢 Dynamic placeholder count to keep a neat grid
            let columns = 2
            let totalSlotsForFullRows = Int(ceil(Double(meditations.count) / Double(columns))) * columns
            let placeholderCount = max(0, totalSlotsForFullRows - meditations.count)

            ScrollView {
                VStack(spacing: vSpacing) {
                    HStack {
                        Spacer(minLength: 0)
                        QuickStartMeditationCard {
                            showQuickStartDurations = true
                        }
                        Spacer(minLength: 0)
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: hSpacing),
                            GridItem(.flexible(), spacing: hSpacing)
                        ],
                        spacing: vSpacing
                    ) {
                        // 1) Real meditations (tappable)
                        ForEach(meditations) { m in
                            NavigationLink {
                                PrayerMeditationView(meditation: m)
                            } label: {
                                ScaleOnScrollCard(baseSize: cardSize) {
                                    MeditationCard(meditation: m, baseSize: cardSize)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        // 2) Placeholder cards to complete the last row (non-tappable)
                        ForEach(0..<placeholderCount, id: \.self) { _ in
                            ScaleOnScrollCard(baseSize: cardSize) {
                                ComingSoonCard(baseSize: cardSize)
                            }
                            .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(
                NavigationLink("", isActive: $showQuickStartSession) {
                    QuickStartMeditationSessionView(
                        duration: selectedQuickStartDuration ?? MeditationDurationOption.default
                    )
                }
                .hidden()
            )
        }
        .sheet(isPresented: $showQuickStartDurations) {
            MeditationDurationPickerSheet(
                selectedDuration: selectedQuickStartDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedQuickStartDuration = duration
                showQuickStartDurations = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showQuickStartSession = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Prayerful Meditations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            handlePendingDeepLink(vm.pendingDeepLink)
        }
        .onChange(of: vm.pendingDeepLink) { destination in
            handlePendingDeepLink(destination)
        }
    }

    private func handlePendingDeepLink(_ destination: AppViewModel.DeepLinkDestination?) {
        guard destination == .quickStartMeditation else { return }
        vm.pendingDeepLink = nil
        showQuickStartDurations = true
    }
}
