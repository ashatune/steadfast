// AnchorService.swift
import Foundation

final class AnchorService {
    static let shared = AnchorService()

    private let anchors: [Verse] = [
        Verse(ref: "Philippians 4:6–7",
              breathIn: "Do not be anxious about anything",
              breathOut: "God’s peace guards my heart and mind",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 41:10",
              breathIn: "Fear not, for I am with you",
              breathOut: "I will strengthen and uphold you",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 23:4",
              breathIn: "Even though I walk through the valley",
              breathOut: "You are with me, I will not fear",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 27:1",
              breathIn: "The Lord is my light and my salvation",
              breathOut: "Whom shall I fear?",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 34:4",
              breathIn: "I sought the Lord",
              breathOut: "He answered me and delivered me from fear",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 46:1–3",
              breathIn: "God is my refuge and strength",
              breathOut: "I will not fear though the earth gives way",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 55:22",
              breathIn: "I cast my cares on the Lord",
              breathOut: "He sustains me and I will not be shaken",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 56:3",
              breathIn: "When I am afraid",
              breathOut: "I put my trust in You",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 91:1–2",
              breathIn: "I dwell in the shelter of the Most High",
              breathOut: "You are my refuge and fortress",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 94:19",
              breathIn: "When anxiety is great within me",
              breathOut: "Your comfort brings me joy",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 121:1–2",
              breathIn: "I lift my eyes to the hills",
              breathOut: "My help comes from the Lord",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Matthew 6:25–34",
              breathIn: "I will not worry about tomorrow",
              breathOut: "My Father knows what I need",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Matthew 11:28–30",
              breathIn: "Come to Me, all who are weary",
              breathOut: "I will give you rest",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "John 14:27",
              breathIn: "My peace I leave with you",
              breathOut: "Let not your heart be troubled",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "John 16:33",
              breathIn: "In this world you will have trouble",
              breathOut: "Take heart, I have overcome the world",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Joshua 1:9",
              breathIn: "Be strong and courageous",
              breathOut: "The Lord your God is with you",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Deuteronomy 31:8",
              breathIn: "The Lord goes before me",
              breathOut: "He will never leave or forsake me",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Proverbs 3:5–6",
              breathIn: "Trust in the Lord with all your heart",
              breathOut: "He will make your paths straight",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "1 Peter 5:7",
              breathIn: "Cast all your anxiety on Him",
              breathOut: "Because He cares for you",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "2 Timothy 1:7",
              breathIn: "God gave me a spirit of power and love",
              breathOut: "Not a spirit of fear",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Romans 8:28",
              breathIn: "All things work together for good",
              breathOut: "For those who love God",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Romans 8:38–39",
              breathIn: "Nothing can separate me",
              breathOut: "From the love of God",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Lamentations 3:22–23",
              breathIn: "The steadfast love of the Lord never ceases",
              breathOut: "His mercies are new every morning",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Nahum 1:7",
              breathIn: "The Lord is good, a refuge in trouble",
              breathOut: "He cares for those who trust in Him",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Zephaniah 3:17",
              breathIn: "The Lord rejoices over me with gladness",
              breathOut: "He quiets me with His love",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Hebrews 13:5–6",
              breathIn: "God will never leave me",
              breathOut: "The Lord is my helper; I will not fear",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Hebrews 4:16",
              breathIn: "I approach God’s throne with confidence",
              breathOut: "To receive mercy and grace in time of need",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 26:3",
              breathIn: "You keep in perfect peace",
              breathOut: "Those whose minds are steadfast",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 35:4",
              breathIn: "Be strong and do not fear",
              breathOut: "Your God will come to save you",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 43:1–2",
              breathIn: "Do not fear, I have redeemed you",
              breathOut: "I will be with you through the waters",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 18:2",
              breathIn: "The Lord is my rock and fortress",
              breathOut: "My God in whom I take refuge",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 37:5",
              breathIn: "Commit your way to the Lord",
              breathOut: "Trust Him and He will act",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 40:1–3",
              breathIn: "I waited patiently for the Lord",
              breathOut: "He set my feet on solid ground",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 112:7",
              breathIn: "My heart is steadfast, trusting the Lord",
              breathOut: "I have no fear of bad news",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 118:6",
              breathIn: "The Lord is on my side",
              breathOut: "I will not fear",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 119:114",
              breathIn: "You are my refuge and shield",
              breathOut: "I put my hope in Your word",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 145:18–19",
              breathIn: "The Lord is near to all who call on Him",
              breathOut: "He fulfills the desires of those who fear Him",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Colossians 3:15",
              breathIn: "Let the peace of Christ rule in my heart",
              breathOut: "And be thankful",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Ephesians 6:10–11",
              breathIn: "Be strong in the Lord",
              breathOut: "Put on the full armor of God",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "1 Thessalonians 5:16–18",
              breathIn: "Rejoice always",
              breathOut: "Pray continually, give thanks in all things",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Galatians 6:9",
              breathIn: "Do not grow weary in doing good",
              breathOut: "At the proper time I will reap a harvest",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "James 1:2–4",
              breathIn: "Consider it joy when I face trials",
              breathOut: "Testing produces perseverance and maturity",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "James 4:8",
              breathIn: "Come near to God",
              breathOut: "And He will come near to you",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Micah 7:7",
              breathIn: "I watch in hope for the Lord",
              breathOut: "My God will hear me",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Proverbs 12:25",
              breathIn: "Anxiety weighs the heart down",
              breathOut: "A kind word cheers it up",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Proverbs 16:3",
              breathIn: "Commit to the Lord whatever you do",
              breathOut: "He will establish your plans",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Proverbs 18:10",
              breathIn: "The name of the Lord is a strong tower",
              breathOut: "I am safe within His presence",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 4:8",
              breathIn: "In peace I lie down and sleep",
              breathOut: "You alone, Lord, make me dwell in safety",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 16:8",
              breathIn: "I keep my eyes always on the Lord",
              breathOut: "With Him at my right hand I will not be shaken",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 62:5–8",
              breathIn: "Yes, my soul finds rest in God",
              breathOut: "My hope and refuge are in Him",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 73:26",
              breathIn: "My flesh and heart may fail",
              breathOut: "God is the strength of my heart forever",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Psalm 103:1–5",
              breathIn: "Bless the Lord, O my soul",
              breathOut: "Forget not all His benefits",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 40:31",
              breathIn: "Those who hope in the Lord will renew strength",
              breathOut: "They will soar on wings like eagles",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Isaiah 54:10",
              breathIn: "Though mountains be shaken",
              breathOut: "My love for you will not be removed",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Jeremiah 29:11–13",
              breathIn: "I know the plans I have for you",
              breathOut: "Plans to give you hope and a future",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Jeremiah 17:7–8",
              breathIn: "Blessed is the one who trusts in the Lord",
              breathOut: "They will be like a tree planted by water",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Matthew 10:29–31",
              breathIn: "Even the hairs on your head are numbered",
              breathOut: "So do not be afraid; you are valuable",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Mark 4:39–40",
              breathIn: "Peace, be still",
              breathOut: "Why are you afraid? Trust in Me",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Luke 12:32",
              breathIn: "Do not be afraid, little flock",
              breathOut: "Your Father is pleased to give you the kingdom",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "2 Corinthians 12:9–10",
              breathIn: "My grace is sufficient for you",
              breathOut: "My power is made perfect in weakness",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Colossians 1:11",
              breathIn: "Be strengthened with all power",
              breathOut: "So you may endure with patience and joy",
              audioFile: "wanderingMeditation.mp3"),

        Verse(ref: "Revelation 21:4",
              breathIn: "God will wipe away every tear",
              breathOut: "There will be no more pain or sorrow",
              audioFile: "wanderingMeditation.mp3")
    ]

    func anchorsForToday(count: Int = 3,
                         date: Date = Date(),
                         calendar: Calendar = .current) -> [Verse] {
        guard !anchors.isEmpty else { return [Verse(ref: "Psalm 56:3")] }

        let comps = calendar.dateComponents([.year], from: date)
        let year = comps.year ?? 2025
        let ord = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let day = ord - 1
        let shuffled = deterministicallyShuffled(anchors, seed: year)
        return (0..<max(1, count)).map { i in
            shuffled[(day + i) % shuffled.count]
        }
    }

    private func deterministicallyShuffled<T>(_ arr: [T], seed: Int) -> [T] {
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        return arr.shuffled(using: &rng)
    }
}

fileprivate struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        var x = state
        x ^= x >> 12; x ^= x << 25; x ^= x >> 27
        state = x
        return x &* 0x2545F4914F6CDD1D
    }
}
