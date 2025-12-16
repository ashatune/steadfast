import WidgetKit
import SwiftUI
import Foundation

// MARK: - Shared App Group ID
private let appGroupID = "group.ashatune.Steadfast"


// MARK: - Entry
struct AnchorEntry: TimelineEntry {
    let date: Date
    let ref: String
    let inhale: String
    let exhale: String
    let lastUpdated: Date?
}


// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AnchorEntry {
        AnchorEntry(
            date: .now,
            ref: "1 Peter 5:7",
            inhale: "Cast all your care",
            exhale: "for He cares for you",
            lastUpdated: nil
        )
    }


    func getSnapshot(in context: Context, completion: @escaping (AnchorEntry) -> Void) {
        completion(loadCurrentEntry() ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnchorEntry>) -> Void) {
        let entry = loadCurrentEntry() ?? placeholder(in: context)

        // Your existing refresh plan is fine:
        let cal = Calendar.current
        let nextMidnight = cal.startOfDay(for: Date().addingTimeInterval(60*60*24))
        let refresh = min(nextMidnight.addingTimeInterval(60*5), Date().addingTimeInterval(60*30))

        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadCurrentEntry() -> AnchorEntry? {
        // 1) Try the new single-payload path
        if let p = SharedStore.load() {
            print("🔵 Widget READ payload @ \(p.lastUpdated)")
            return AnchorEntry(date: .now, ref: p.ref, inhale: p.inhale, exhale: p.exhale, lastUpdated: p.lastUpdated)
        }

        // 2) Fallback: legacy keys (keeps compatibility during transition)
        let groupID = "group.ashatune.Steadfast"
        guard let shared = UserDefaults(suiteName: groupID) else {
            print("🔴 Widget: UserDefaults suite not found.")
            return nil
        }

        let ref    = shared.string(forKey: "widget_ref") ?? ""
        let inhale = shared.string(forKey: "widget_inhale") ?? ""
        let exhale = shared.string(forKey: "widget_exhale") ?? ""

        guard !ref.isEmpty || !inhale.isEmpty || !exhale.isEmpty else { return nil }

        // Optional: migrate legacy keys into the new payload so future reads are unified
        let migrated = AnchorPayload(ref: ref, inhale: inhale, exhale: exhale, lastUpdated: .now)
        SharedStore.save(migrated)
        print("🟡 Widget migrated legacy keys into payload.")

        return AnchorEntry(date: .now, ref: ref, inhale: inhale, exhale: exhale, lastUpdated: migrated.lastUpdated)
    }

}


// MARK: - View
struct AnchorWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: AnchorEntry

    var body: some View {
        switch family {

        // ✅ Home Screen: your existing full-bleed image version
        case .systemSmall, .systemMedium:
            HomeScreenAnchorView(entry: entry)

        // ✅ Lock Screen rectangular
        case .accessoryRectangular:
            AccessoryRectAnchorView(entry: entry)

        // ✅ Lock Screen inline (status line)
        case .accessoryInline:
            Text("Inhale: \(entry.inhale)  •  Exhale: \(entry.exhale)")
                .font(.caption2)
                .widgetAccentable() // adopts Lock Screen tint

        // ✅ Lock Screen circular (very tight space)
        case .accessoryCircular:
            VStack(spacing: 1) {
                Text("🙏") // emoji works great at this size
                    .font(.system(size: 14))
                Text("Inhale HIS Peace")
                    .font(.system(size: 7, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text("Exhale Doubt")
                    .font(.system(size: 7))
                    .opacity(0.85)
                    .multilineTextAlignment(.center)
            }
            .widgetAccentable()



        @unknown default:
            HomeScreenAnchorView(entry: entry)
        }
    }
}

struct AccessoryRectAnchorView: View {
    var entry: AnchorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // INHALE
            HStack(spacing: 4) {
                Text("Inhale:")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(entry.inhale)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .lineLimit(1)
            }

            // EXHALE
            HStack(spacing: 4) {
                Text("Exhale:")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text(entry.exhale)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .lineLimit(1)
            }

            Text(entry.ref)
                .font(.caption2)
                .lineLimit(1)
                .padding(.top, 1)
        }
        .widgetAccentable() // adopt system tint; ensures good contrast
    }
}


struct HomeScreenAnchorView: View {
    var entry: AnchorEntry
    final class AnchorWidgetBundleSentinel {}

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Inhale:").font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text(entry.inhale).font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .shadow(radius: 3)

                HStack(spacing: 4) {
                    Text("Exhale:").font(.system(size: 16, weight: .regular, design: .rounded))
                    Text(entry.exhale).font(.system(size: 16, weight: .regular, design: .rounded))
                }
                .shadow(radius: 2)

                Text(entry.ref)
                    .font(.caption2)
                    .padding(.top, 4)
                
                if let ts = entry.lastUpdated {
                    Text(ts.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .opacity(0.6)
                }
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .contentMargins(.zero)
        .containerBackground(for: .widget) {
            if let ui = UIImage(
                named: "widgetBG",
                in: Bundle(for: AnchorWidgetBundleSentinel.self), // any type that lives in the widget target
                with: nil
            ) {
                Image(uiImage: ui)
                    .renderingMode(.original)  
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.15)],
                                       startPoint: .bottom, endPoint: .top)
                    )
                    .clipped()
            } else {
                Color.gray
                Text("Missing widgetBG").font(.caption2).foregroundStyle(.white)
            }
        }
        .widgetURL(URL(string: "steadfast://open/anchor-breathe"))
    }
}



// MARK: - Widget

struct AnchorWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AnchorWidget", provider: Provider()) { entry in
            AnchorWidgetView(entry: entry)       // will branch by family
        }
        .configurationDisplayName("Steadfast Anchor")
        .description("Inhale scripture. Exhale worry.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryRectangular, .accessoryInline, .accessoryCircular]) // 👈
    }
}

