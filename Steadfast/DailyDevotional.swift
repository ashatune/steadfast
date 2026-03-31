import Foundation

struct DailyDevotional: Identifiable, Codable {
    var id: String
    var date: Date
    var title: String
    var verseReference: String
    var verseText: String
    var body: String
    var cta: String?
    var imageURL: URL?
}

extension DailyDevotional {
    static func placeholder(for date: Date = .now) -> DailyDevotional {
        fallback(for: date)
    }

    static func fallback(for date: Date = .now) -> DailyDevotional {
        let dateKey = fallbackDateFormatter.string(from: date)
        guard !fallbackDevotionals.isEmpty else {
            assertionFailure("Fallback devotionals should not be empty")
            return DailyDevotional(
                id: "placeholder-\(dateKey)-empty-pool",
                date: date,
                title: "Trust the Lord Today",
                verseReference: "Proverbs 3:5",
                verseText: "Trust in the Lord with all your heart and lean not on your own understanding.",
                body: "Even when plans fail and answers feel far away, the Lord remains faithful. Bring Him your uncertainty and ask for steady trust today.",
                cta: "Give one concern to God and ask for His peace."
            )
        }

        let index = fallbackIndex(for: date)
        var devotional = fallbackDevotionals[index]
        devotional.id = "placeholder-\(dateKey)-\(index)"
        devotional.date = date
        return devotional
    }

    var previewSnippet: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 140 { return trimmed }
        let endIdx = trimmed.index(trimmed.startIndex, offsetBy: 140, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        return "\(trimmed[..<endIdx])…"
    }

    private static func fallbackIndex(for date: Date) -> Int {
        guard !fallbackDevotionals.isEmpty else {
            assertionFailure("Fallback devotionals should not be empty")
            return 0
        }

        let key = fallbackDateFormatter.string(from: date)
        var value = 0
        for scalar in key.unicodeScalars {
            value = (value * 31 + Int(scalar.value)) % fallbackDevotionals.count
        }
        return value
    }

    private static let fallbackDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let fallbackDevotionals: [DailyDevotional] = [
        DailyDevotional(
            id: "placeholder-template-0",
            date: .distantPast,
            title: "Trusting God When You Can’t See the Whole Path",
            verseReference: "Proverbs 3:5-6",
            verseText: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to Him, and He will make your paths straight.",
            body: """
            There are seasons when life feels uncertain and unfinished. You may be doing your best to move forward while quietly wondering what God is doing, why things are taking so long, or how everything will work out. In moments like that, trust can feel difficult—not because you do not love God, but because you cannot yet see the full picture.

            Proverbs 3 reminds us that peace is not found in figuring everything out. Peace is found in placing our weight on the One who already sees the road ahead. Trusting the Lord does not mean pretending life is easy. It means choosing to believe that His wisdom is greater than your fear, His timing is better than your urgency, and His care for you is deeper than what you can measure right now.

            You do not need every answer today. You do not need to force clarity where God is asking for faith. Sometimes trusting Him looks like taking the next small step, offering Him your worries again, and believing that He is still leading you even when the path feels foggy.

            God is not confused about your future. He is not behind. He is not distant. He is present in the waiting, faithful in the unknown, and steady when your heart feels shaky. Today, let trust be simple: not having it all figured out, but handing your uncertainty to the Lord and letting Him carry what you cannot.
            """,
            cta: "Take one worry you’ve been carrying and quietly surrender it to God. Ask Him to help you trust Him with today, not just tomorrow."
        ),
        DailyDevotional(
            id: "placeholder-template-1",
            date: .distantPast,
            title: "God Is Steady When Life Feels Unstable",
            verseReference: "Psalm 56:3",
            verseText: "When I am afraid, I put my trust in You.",
            body: """
            Fear has a way of making everything feel fragile. What once felt manageable can suddenly feel uncertain. Your thoughts can begin racing ahead, imagining worst-case scenarios and searching for control. But Psalm 56 gives us a simple and honest response: “When I am afraid, I put my trust in You.”

            Notice that the verse does not say “if.” It says “when.” God already knows that fear will visit us. He knows there will be moments when our hearts feel unsettled. Trusting Him does not require you to be fearless first. It means bringing your fear to Him as it is and letting your heart rest in His strength instead of your own.

            God is not asking you to hold yourself together by yourself. He is inviting you to lean on Him. He remains steady when your emotions are not. He remains faithful when your thoughts feel loud. He remains near when you feel overwhelmed. Fear may be present, but it does not get the final word. Trust does.

            Today, if life feels unsteady, remember this: the Lord is still your anchor. He is not shaken by what shakes you. He is not overwhelmed by what overwhelms you. You can be honest about your fears and still choose to place them into His hands. That is what trust looks like—returning to God again and again until your heart remembers where its safety is found.
            """,
            cta: "Pause and tell God plainly what is making you afraid. Then repeat: “When I am afraid, I put my trust in You.”"
        ),
        DailyDevotional(
            id: "placeholder-template-2",
            date: .distantPast,
            title: "Trusting God With What You Cannot Control",
            verseReference: "Isaiah 26:3-4",
            verseText: "You will keep in perfect peace those whose minds are steadfast, because they trust in You. Trust in the Lord forever, for the Lord, the Lord Himself, is the Rock eternal.",
            body: """
            So much of our stress comes from trying to manage what was never fully ours to control. We replay conversations, predict outcomes, overanalyze decisions, and carry responsibility for things that belong in God’s hands. The result is exhaustion. Our minds get crowded, and our peace starts to slip away.

            Isaiah points us back to a better place: trust. Perfect peace is not promised to the person who controls everything. It is promised to the person whose mind is fixed on God. That means peace grows when our attention shifts from the problem to the Lord, from the unknown to the One who never changes.

            Trusting God does not mean you stop caring. It means you stop trying to carry what only He can hold. It means admitting that your strength has limits, but His does not. It means believing that the Rock eternal can support the weight of your future, your needs, your questions, and your healing.

            You are allowed to rest in God’s steadiness today. You are allowed to release the pressure to solve everything immediately. The Lord is not asking you to be the rock. He is inviting you to stand on Him instead.
            """,
            cta: "Ask yourself: “What am I trying to control today?” Name it, release it, and ask God to trade your tension for His peace."
        ),
        DailyDevotional(
            id: "placeholder-template-3",
            date: .distantPast,
            title: "Waiting Does Not Mean God Has Forgotten You",
            verseReference: "Lamentations 3:25-26",
            verseText: "The Lord is good to those whose hope is in Him, to the one who seeks Him; it is good to wait quietly for the salvation of the Lord.",
            body: """
            Waiting can feel heavy. It can make you question whether God is moving at all. When prayers seem unanswered and situations remain unresolved, it is easy to assume that silence means absence. But Scripture tells a different story. The Lord is good to those whose hope is in Him, even in the waiting.

            God’s goodness is not limited to quick answers. Sometimes His goodness is what sustains you while the answer is still forming. Sometimes His faithfulness is shown not by immediate change, but by His presence with you through every uncertain day.

            Waiting with God is different from waiting without Him. Waiting with God can still hold hope. It can still hold peace. It can still hold quiet confidence that the Lord is at work in ways you cannot yet see. A delayed answer is not the same as abandonment. A slower timeline is not the same as neglect.

            If you are tired of waiting, you are not failing. Bring that weariness to God too. He is gentle with tired hearts. He knows how long the road has felt. And He is still trustworthy here, not just at the finish line, but in the middle of the process.

            The Lord has not forgotten you. He sees what you are carrying. He is with you in the silence. And He is still worthy of your trust, even here.
            """,
            cta: "If you’ve been waiting on God in one area of your life, offer that waiting to Him today. Ask for grace to trust Him one day at a time."
        )
    ]
}
