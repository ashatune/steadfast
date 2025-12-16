import SwiftUI

struct DailyRhythmView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showMorning = false
    @State private var showMidday  = false
    @State private var showEvening = false
    @Environment(\.colorScheme) var colorScheme

    private let cardWidth: CGFloat  = 180
    private let cardHeight: CGFloat = 110
    
    private let slots: [DailySlot] = [
        .init(title: "Morning", subtitle: "Verse + Reflect", systemImage: "sun.max.fill",   imageName: "MorningCard"),
        .init(title: "Midday",  subtitle: "Breath reset",        systemImage: "wind",          imageName: "MiddayCard"),
        .init(title: "Evening", subtitle: "Reflect & Release",   systemImage: "moon.stars.fill", imageName: "EveningCard")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Daily Rhythm").font(.title3).bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(slots) { slot in
                        ScalingDailyCard(
                            slot: slot,
                            baseSize: CGSize(width: cardWidth, height: cardHeight),
                            onTap: action(for: slot)
                        )
                    }
                }
                .padding(.vertical, 0)
            }
            
            // Hidden navigation triggers
            NavigationLink("", isActive: $showMorning) {
                MorningFlowView(
                    verse: pickVerseForMorning(),
                    totalSeconds: 180, inhaleSecs: 4, exhaleSecs: 6
                )
            }.hidden()
            
            NavigationLink("", isActive: $showMidday) {
                MiddayFlowView(totalSeconds: 90, boxCount: 4)
            }.hidden()
            
            NavigationLink("", isActive: $showEvening) {
                EveningFlowView(totalSeconds: 60, inhaleSecs: 3, exhaleSecs: 6)
            }.hidden()
        }
        // Theme (no background here—HomeView owns page bg)
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .onChange(of: vm.pendingDeepLink) { dest in
            guard let dest = dest else { return }

            switch dest {
            case .morning:
                showMorning = true
            case .midday:
                showMidday = true
            case .evening:
                showEvening = true
            case .anchor:
                // ignore here; handled in HomeView
                break
            }

            vm.pendingDeepLink = nil
        }
    }
    
    private func action(for slot: DailySlot) -> (() -> Void)? {
        switch slot.title {
        case "Morning": return { showMorning = true }
        case "Midday":  return { showMidday  = true }
        case "Evening": return { showEvening = true }
        default:        return nil
        }
    }
    
    private func pickVerseForMorning() -> Verse {
        vm.todayVerses.first
        ?? vm.library.packs.first?.verses.first
        ?? Verse(
            ref: "Psalm 56:3",
            breathIn: "When I am afraid",
            breathOut: "I put my trust in You"
        )
    }
    
    
    struct DailySlot: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemImage: String
        let imageName: String
    }
    
    
    struct ScalingDailyCard: View {
        let slot: DailySlot
        let baseSize: CGSize
        var onTap: (() -> Void)? = nil
        
        var body: some View {
            GeometryReader { geo in
                let midX = geo.frame(in: .global).midX
                let screenMidX = UIScreen.main.bounds.width / 2
                let distance = abs(midX - screenMidX)
                let scale = max(0.9, 1.15 - (distance / 600))
                
                ZStack(alignment: .bottomLeading) {
                    // Background image
                    Image(slot.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: baseSize.width, height: baseSize.height)
                        .clipped()
                    
                    // Readability overlay (top-to-bottom wash)
                    LinearGradient(
                        colors: [.black.opacity(0.0), .black.opacity(0.25), .black.opacity(0.45)],
                        startPoint: .top, endPoint: .bottom
                    )
                    
                    // Content overlay (icon + text)
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: slot.systemImage)
                            .foregroundStyle(.white)
                        Text(slot.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                        Text(slot.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(12)
                }
                .frame(width: baseSize.width, height: baseSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18)))
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                .scaleEffect(scale, anchor: .center)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: scale)
                .contentShape(Rectangle())
                .onTapGesture { onTap?() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(slot.title). \(slot.subtitle)")
            }
            .frame(width: baseSize.width, height: baseSize.height)
        }
    }
    
}
