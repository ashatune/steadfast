import WidgetKit
import SwiftUI
import Foundation


// MARK: - Entry
struct AnchorEntry: TimelineEntry {
    let date: Date
    let text: String
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
            text: "Cast all your anxiety on Him because He cares for you.",
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
        if let payload = AnchorOfDayStore.load() {
            print("🔵 Widget READ anchor payload @ \(payload.lastUpdated)")
            return AnchorEntry(
                date: payload.anchorDate,
                text: payload.text,
                ref: payload.ref,
                inhale: payload.inhale,
                exhale: payload.exhale,
                lastUpdated: payload.lastUpdated
            )
        }

        // Fallback: legacy SharedStore (keeps compatibility during transition)
        if let compat = SharedStore.load() {
            print("🟡 Widget migrated legacy SharedStore payload.")
            let migrated = AnchorOfDayPayload(
                id: compat.ref,
                ref: compat.ref,
                text: "",
                inhale: compat.inhale,
                exhale: compat.exhale,
                anchorDate: .now,
                lastUpdated: compat.lastUpdated
            )
            AnchorOfDayStore.save(migrated)
            return AnchorEntry(
                date: migrated.anchorDate,
                text: migrated.text,
                ref: migrated.ref,
                inhale: migrated.inhale,
                exhale: migrated.exhale,
                lastUpdated: migrated.lastUpdated
            )
        }

        // Store and return the same fallback the app would use so both stay aligned
        let fallback = AnchorOfDayStore.fallbackPayload(anchorDate: Calendar.current.startOfDay(for: Date()))
        AnchorOfDayStore.save(fallback)
        return AnchorEntry(
            date: fallback.anchorDate,
            text: fallback.text,
            ref: fallback.ref,
            inhale: fallback.inhale,
            exhale: fallback.exhale,
            lastUpdated: fallback.lastUpdated
        )
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

    private var anchorDeepLink: URL? {
        var comps = URLComponents()
        comps.scheme = "steadfast"
        comps.host = "anchor-of-day"
        comps.queryItems = [
            URLQueryItem(name: "id", value: entry.ref)
        ]
        return comps.url
    }

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
        .widgetURL(anchorDeepLink)
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
