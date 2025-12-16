import Foundation

struct ScriptureLibrary: Codable {
    var packs: [VersePack]
    var prayerPlans: [PrayerPlan]
}

struct VersePack: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var verses: [Verse]
    var reflections: [Reflection]

    // NEW (all optional so older JSON still decodes)
    var reflectionHeader: String?
    var reflectionSubtitle: String?
    var reflectionTokens: [String]?
}


/*struct Verse: Codable, Identifiable, Hashable {
    var id: String { ref }
    var ref: String
    var breathIn: String?
    var breathOut: String?
    var text: String?
}*/


struct Reflection: Codable, Identifiable {
    var id: String
    var title: String
    var durationSec: Int
    var body: String
}

struct PrayerPlan: Codable, Identifiable {
    var id: String
    var title: String
    var steps: [String]
}

enum BibleTranslation: String, CaseIterable, Identifiable { case esv = "ESV", niv = "NIV", csb = "CSB", kjv = "KJV"; var id: String { rawValue } }

// MARK: - Sample Content (Portable JSON -> Decoded)
extension ScriptureLibrary {
    static var sample: ScriptureLibrary {
        let json = Self.sampleJSON.data(using: .utf8)!
        return (try? JSONDecoder().decode(ScriptureLibrary.self, from: json)) ?? ScriptureLibrary(packs: [], prayerPlans: [])
    }

    static let sampleJSON: String = {
        return """
        {
          "packs": [
            {
              "id": "health-anxiety",
                "title": "When health worries spike",
                "description": "Short anchors for illness flare-ups.",
                "reflectionHeader": "Selah",
                "reflectionSubtitle": "Breathe in. Be still.",
                "reflectionTokens": ["You are Protected", "You are covered", "HE is here", "Breathe"],
              "verses": [
                {"ref": "Isaiah 41:10", "breathIn": "Fear not, for I am with you", "breathOut": "I will uphold you"},
                {"ref": "Psalm 23:1-4", "breathIn": "The Lord is my shepherd", "breathOut": "I lack nothing"},
                {"ref": "Psalm 73:26", "breathIn": "God is my strength", "breathOut": "and my portion forever"}
              ],
              "reflections": [
                {"id": "health-1", "title": "Naming the fear", "durationSec": 45, "body": "Gently name the fear without judgment."}
              ]
            },
            {
              "id": "panic-fear",
              "title": "Panic & Fear Surges",
              "description": "Strong promises for acute fear.",
            "reflectionHeader": "Steady Now",
              "reflectionSubtitle": "Right now, you’re safe. God is here.",
              "reflectionTokens": ["Breathe","You are Safe","You are Held","GOD is With You","Breathe in Peace","Exhale","Anchor","Feel the ground under you","Peace be with you","HE is Refuge","HE is your Rock","HE is your protector"],
              "verses": [
                {"ref": "Psalm 61:2", "breathIn": "Lead me to the rock", "breathOut": "that is higher than I"},
                {"ref": "2 Timothy 1:7", "breathIn": "God gave a spirit of power", "breathOut": "love and self-control"},
                {"ref": "Isaiah 43:2", "breathIn": "When you pass through waters", "breathOut": "I will be with you"}
              ],
              "reflections": [
                {"id": "panic-1", "title": "Ride the wave - HE is with you.", "durationSec": 45, "body": "Notice, name, and allow the sensations to crest and fall."}
              ]
            },
            {
              "id": "night-peace",
                "title": "Night Peace",
                "description": "Settle heart and body for sleep.",
                "reflectionHeader": "Wind Down",
                "reflectionSubtitle": "Lay it down for the night.",
                "reflectionTokens": ["Rest in HIM", "Release it to HIM", "Be Gentle", "Quiet your worries"],
              "verses": [
                {"ref": "Psalm 4:8", "breathIn": "In peace I will lie down", "breathOut": "for you alone make me dwell in safety"},
                {"ref": "Proverbs 3:24", "breathIn": "When you lie down", "breathOut": "your sleep will be sweet"},
                {"ref": "Lamentations 3:22-23", "breathIn": "New mercies", "breathOut": "every morning"}
              ],
              "reflections": [
                {"id": "night-1", "title": "Release the day", "durationSec": 60, "body": "Hand over unfinished tasks into God's care."}
              ]
            },
            {
              "id": "daily-worry",
              "title": "Daily Worry & Rumination",
              "description": "Renew the mind with truth.",
        "reflectionHeader": "Cast Your Care",
          "reflectionSubtitle": "One thing at a time. Hand it over.",
          "reflectionTokens": ["Surrender","Trust","Give it to HIM","Cast your worries away","Release","Pray","Do not fear","Give Gratitude","Seek HIM First","Quiet your mind","Rest in HIM","HE gives you Hope"],
              "verses": [
                {"ref": "1 Peter 5:7", "breathIn": "Cast all your cares", "breathOut": "for He cares for you"},
                {"ref": "Matthew 11:28-30", "breathIn": "Come to me", "breathOut": "I will give you rest"},
                {"ref": "Romans 12:2", "breathIn": "Be transformed", "breathOut": "by the renewal of your mind"}
              ],
              "reflections": [
                {"id": "worry-1", "title": "Name it, place it", "durationSec": 45, "body": "Write the worry, then place it under God's care."}
              ]
            }
          ],
          "prayerPlans": [
            {
              "id": "night-peace",
              "title": "Peace at Night",
              "steps": [
                "Settle your breath: 4–7–8 × 3",
                "Read Psalm 4:8",
                "Pray: 'Lord, I lay down in Your safety. Quiet my mind and body.'",
                "Release the day’s worries one-by-one to God",
                "Amen"
              ]
            },
            {
              "id": "illness",
              "title": "Prayer During Illness",
              "steps": [
                "Name the symptom or fear you’re feeling",
                "Read Psalm 23 or Isaiah 41:10",
                "Pray: 'Be my strength today. Hold me in Your care.'",
                "Ask for wisdom for doctors, patience for waiting, and daily grace",
                "Amen"
              ]
            },
            {
              "id": "worry",
              "title": "Prayer for Worry",
              "steps": [
                "Slow breath: 5–5 (inhale 5, exhale 5) × 6",
                "Read 1 Peter 5:7 or Matthew 6:34",
                "Cast each worry to God out loud or in writing",
                "Pray: 'I trust You with what I can’t control.'",
                "Amen"
              ]
            },
            {
              "id": "daily",
              "title": "Prayer for the Day",
              "steps": [
                "Breath: box 4–4–4–4 × 3",
                "Read Psalm 121:1–2 or Proverbs 3:5–6",
                "Pray through your calendar/appointments",
                "Ask for kindness in speech, clarity in decisions, and steady peace",
                "Amen"
              ]
            },
            {
              "id": "lords-prayer",
              "title": "The Lord’s Prayer",
              "steps": [
                "Center your breath for 20–30 seconds",
                "Pray: Our Father which art in heaven, Hallowed be thy name. Thy kingdom come. Thy will be done in earth, as it is in heaven. Give us this day our daily bread. And forgive us our debts, as we forgive our debtors. And lead us not into temptation, but deliver us from evil: For thine is the kingdom, and the power, and the glory, for ever. Amen."
              ]
            }
          ]
        }
        """
    }()
}

// Make VersePack usable in NavigationLink(value:) / navigationDestination(for:)
extension VersePack: Hashable {
    static func == (lhs: VersePack, rhs: VersePack) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
