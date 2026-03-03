import Foundation
import Combine
import SwiftUI
import WidgetKit

extension AppViewModel {
    enum DeepLinkDestination {
        case morning
        case midday
        case evening
        case anchor
        case devotional
    }
}

final class AppViewModel: ObservableObject {
    
    private let appGroupID = AnchorOfDayStore.appGroupID
    @Published var pendingDeepLink: DeepLinkDestination?
    @Published var pendingAnchorID: String?

    // MARK: Personalization / UI
    enum FocusArea: String, CaseIterable, Identifiable { case health, worry, panic, sleep, grief, general
        var id: String { rawValue }
    }
    enum GroundingStyle: String, CaseIterable, Identifiable { case breath, scripture, journal, bodyScan
        var id: String { rawValue }
    }

    // MARK: Stored properties (defaults first)
    @Published var focusAreas: Set<FocusArea>             = [.health, .worry]
    @Published var preferredTranslation: BibleTranslation = .esv
    @Published var groundingStyle: GroundingStyle         = .breath

    @Published var library: ScriptureLibrary              = .sample
    @Published var selectedPack: VersePack?               = nil

    @Published var showSOS: Bool                          = false
    @Published var todayVerses: [Verse]                   = []
    
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    
    // 👇 Single source of truth for the app's anchor of the day
    @Published var anchorOfDay: Verse? = nil {
        didSet { deliverQueuedAnchorDeepLinkIfNeeded() }
    }
    private var anchorDeepLinkQueued = false


    // Profile
    @Published var profileFirstName: String               = "" {
        didSet {
            let trimmed = profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
            if UserDefaults.standard.string(forKey: "displayName") != trimmed {
                UserDefaults.standard.set(trimmed, forKey: "displayName")
            }
            if UserDefaults.standard.string(forKey: "profileFirstName") != trimmed {
                UserDefaults.standard.set(trimmed, forKey: "profileFirstName")
            }
        }
    }
    @Published var profileBirthdate: Date?                = nil
    var profileInitial: String {
        let trimmed = profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map { String($0).uppercased() } ?? "S"
    }

    func syncProfileNameFromDefaults() {
        let trimmedDisplayName = UserDefaults.standard.string(forKey: "displayName")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !trimmedDisplayName.isEmpty {
            profileFirstName = trimmedDisplayName
            return
        }

        let trimmedProfileName = UserDefaults.standard.string(forKey: "profileFirstName")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        profileFirstName = trimmedProfileName
    }

    // Notifications
    @Published var notifEnabled: Bool                     = true
    @Published var morningEnabled: Bool                   = true
    @Published var middayEnabled: Bool                    = true
    @Published var eveningEnabled: Bool                   = true

    @Published var morningTime: Date                      = AppViewModel.makeTime(8, 0)
    @Published var middayTime: Date                       = AppViewModel.makeTime(13, 0)
    @Published var eveningTime: Date                      = AppViewModel.makeTime(21, 0)

    // Voice guidance (TTS) — SINGLE declaration
    @Published var voiceGuidanceEnabled: Bool             = true {
        didSet {
            UserDefaults.standard.set(voiceGuidanceEnabled, forKey: "voice_guidance")
            TTSManager.shared.enabled = voiceGuidanceEnabled
        }
    }

    // MARK: Init
    init() {
        let ud = UserDefaults.standard

        // Load profile name from onboarding
        syncProfileNameFromDefaults()


        // Notifications
        notifEnabled   = (ud.object(forKey: "notif_enabled") as? Bool) ?? notifEnabled
        morningEnabled = (ud.object(forKey: "notif_morning_enabled") as? Bool) ?? morningEnabled
        middayEnabled  = (ud.object(forKey: "notif_midday_enabled") as? Bool) ?? middayEnabled
        eveningEnabled = (ud.object(forKey: "notif_evening_enabled") as? Bool) ?? eveningEnabled

        if let t = ud.object(forKey: "notif_morning_time") as? TimeInterval {
            morningTime = Date(timeIntervalSince1970: t)
        }
        if let t = ud.object(forKey: "notif_midday_time") as? TimeInterval {
            middayTime = Date(timeIntervalSince1970: t)
        }
        if let t = ud.object(forKey: "notif_evening_time") as? TimeInterval {
            eveningTime = Date(timeIntervalSince1970: t)
        }

        // Voice guidance
        if ud.object(forKey: "voice_guidance") != nil {
            voiceGuidanceEnabled = ud.bool(forKey: "voice_guidance")
        }
        TTSManager.shared.enabled = voiceGuidanceEnabled

        NotificationCenter.default.addObserver(forName: .steadfastPendingRoute, object: nil, queue: .main) { [weak self] note in
            if let route = note.object as? String {
                self?.handleRouteToken(route)
            } else if let url = note.object as? URL {
                self?.handleDeepLink(url)
            }
        }

        // Finalize
        refreshToday()
    }

    // MARK: Helpers
    static func makeTime(_ hour: Int, _ minute: Int) -> Date {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: Refresh & Selection
    func refreshToday(date: Date = Date()) {
        // Build today's candidate list (kept if you use elsewhere)
        var picks: [Verse] = []
        let packs = prioritizedPacks()
        for p in packs { if let v = p.verses.first { picks.append(v) } }
        todayVerses = picks

        // ✅ Compute one anchor for the day (single source of truth)
        let anchor = DailyVerseProvider.shared.verse(for: date, calendar: Calendar.current)
        anchorOfDay = anchor

        // ✅ Schedule 11:00am anchor-verse notification with the SAME verse
        NotificationManager.shared.scheduleAnchorVerseAt11IfEnabled()

        // ✅ Persist SAME verse for the widget + reload its timeline
        syncAnchorWithWidget(anchor: anchor, anchorDate: date)
    }

    // MARK: - Deep link handling
    func consumePendingRouteFromDefaults() {
        let ud = UserDefaults.standard
        guard let route = ud.string(forKey: DeepLinkRoute.pendingRouteDefaultsKey) else { return }
        ud.removeObject(forKey: DeepLinkRoute.pendingRouteDefaultsKey)
        handleRouteToken(route)
    }

    func handleDeepLink(_ url: URL) {
        guard DeepLinkRoute.isSteadfastURL(url) else { return }

        let path = url.path.lowercased()
        let host = url.host?.lowercased()

        // Recognize anchor routes like steadfast://anchor/exercise or legacy steadfast://anchor-of-day
        if DeepLinkRoute.isAnchorExercise(url) {
            let anchorID = DeepLinkRoute.anchorIdentifier(from: url)
            triggerAnchorNavigation(anchorID: anchorID)
            return
        }

        if host == "devotional" || path.contains("/devotional") || path.contains("devotional/today") {
            pendingDeepLink = .devotional
            return
        }

        if host == "morning" || path.contains("/morning") {
            pendingDeepLink = .morning
            return
        }
        if host == "midday" || path.contains("/midday") {
            pendingDeepLink = .midday
            return
        }
        if host == "evening" || path.contains("/evening") {
            pendingDeepLink = .evening
            return
        }
    }

    private func handleRouteToken(_ route: String) {
        if let url = URL(string: route) {
            handleDeepLink(url)
            return
        }

        switch route {
        case "morning":
            pendingDeepLink = .morning
        case "midday":
            pendingDeepLink = .midday
        case "evening":
            pendingDeepLink = .evening
        case "anchor":
            triggerAnchorNavigation(anchorID: nil)
        case "devotional", "devotional/today", "dailyDevotional":
            pendingDeepLink = .devotional
        default:
            break
        }
    }

    private func triggerAnchorNavigation(anchorID: String?) {
        pendingAnchorID = anchorID

        if let anchorID, let resolved = AnchorService.shared.anchor(matching: anchorID) {
            anchorOfDay = resolved
        }

        if anchorOfDay != nil {
            anchorDeepLinkQueued = false
            pendingDeepLink = .anchor
            return
        }

        anchorDeepLinkQueued = true
        refreshToday()
    }

    private func deliverQueuedAnchorDeepLinkIfNeeded() {
        guard anchorDeepLinkQueued else { return }
        if anchorOfDay != nil {
            pendingDeepLink = .anchor
        } else {
            pendingDeepLink = nil
        }
        anchorDeepLinkQueued = false
    }

    /// Write shared values for the WIDGET using the SAME anchorOfDay and reload
    private func syncAnchorWithWidget(anchor: Verse?, anchorDate: Date) {
        if let v = anchor {
            let payload = AnchorOfDayStore.save(
                verse: v,
                anchorDate: Calendar.current.startOfDay(for: anchorDate),
                lastUpdated: Date()
            )
            print("🟢 Saved anchor for widget @ \(payload.lastUpdated) ref=\(payload.ref)")
        } else {
            // Keep widget + app aligned with the same default when no anchor is available
            let fallback = AnchorOfDayStore.fallbackPayload(anchorDate: Calendar.current.startOfDay(for: anchorDate))
            AnchorOfDayStore.save(fallback)
            anchorOfDay = Verse(ref: fallback.ref, text: fallback.text, breathIn: nil, breathOut: nil, audioFile: nil, inhaleCue: fallback.inhale, exhaleCue: fallback.exhale)
            print("🟡 Stored fallback anchor for widget @ \(fallback.lastUpdated) ref=\(fallback.ref)")
        }

        // Reload widget timelines so data refreshes promptly
        WidgetCenter.shared.reloadTimelines(ofKind: "AnchorWidget")
    }



    // AppViewModel.swift
    func setTodayAnchor(ref: String, inhale: String, exhale: String) {
        let verse = Verse(ref: ref, text: "", breathIn: nil, breathOut: nil, audioFile: nil, inhaleCue: inhale, exhaleCue: exhale)
        anchorOfDay = verse
        let payload = AnchorOfDayStore.save(
            verse: verse,
            anchorDate: Calendar.current.startOfDay(for: Date()),
            lastUpdated: Date()
        )
        print("🟢 Manually set anchor for widget @ \(payload.lastUpdated) ref=\(payload.ref)")
        WidgetCenter.shared.reloadTimelines(ofKind: "AnchorWidget")
    }



    func prioritizedPacks() -> [VersePack] {
        let map: [FocusArea: String] = [
            .health: "health-anxiety",
            .panic:  "panic-fear",
            .sleep:  "night-peace",
            .worry:  "daily-worry",
            .grief:  "daily-worry",
            .general:"health-anxiety"
        ]
        let wanted = focusAreas.compactMap { map[$0] }
        let selected = library.packs.filter { wanted.contains($0.id) }
        return selected.isEmpty ? Array(library.packs.prefix(4)) : selected
    }
    
    // Build a short banner line for today’s anchor verse (nil-safe)
    func anchorVerseTextForToday() -> String {
        guard let v = todayVerses.first else {
            return "“Be still, and know that I am God.” — Psalm 46:10"
        }

        let text = v.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let ref  = v.ref.trimmingCharacters(in: .whitespacesAndNewlines)

        let biStr: String = {
            if let cue = v.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
            if let secs = v.breathIn { return "Inhale \(secs)s" }
            return ""
        }()

        let boStr: String = {
            if let cue = v.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
            if let secs = v.breathOut { return "Exhale \(secs)s" }
            return ""
        }()

        if !text.isEmpty {
            return "“\(text)”" + (ref.isEmpty ? "" : " — \(ref)")
        }

        let parts = [biStr, boStr].filter { !$0.isEmpty }
        if !parts.isEmpty {
            let line = parts.joined(separator: " / ")
            return "“\(line)”" + (ref.isEmpty ? "" : " — \(ref)")
        }

        return ref.isEmpty ? "“Be still, and know that I am God.” — Psalm 46:10" : ref
    }



}
