import Foundation
import Testing
import UIKit
@testable import Steadfast

struct SteadfastTests {
    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func anchorChangesBetweenConsecutiveLocalCalendarDates() {
        let calendar = calendar("America/Chicago")
        let first = date(2026, 7, 16, 12, 0, in: calendar)
        let second = date(2026, 7, 17, 12, 0, in: calendar)

        #expect(DailyAnchorResolver.anchor(for: first, calendar: calendar).ref != DailyAnchorResolver.anchor(for: second, calendar: calendar).ref)
    }

    @Test func multipleReadsOnSameDateReturnSameAnchor() {
        let calendar = calendar("America/Chicago")
        let morning = date(2026, 7, 16, 8, 0, in: calendar)
        let evening = date(2026, 7, 16, 22, 30, in: calendar)

        #expect(DailyAnchorResolver.anchor(for: morning, calendar: calendar).ref == DailyAnchorResolver.anchor(for: evening, calendar: calendar).ref)
    }

    @Test func widgetAndMainAppResolveSameAnchorForGivenDate() {
        let calendar = calendar("America/New_York")
        let today = date(2026, 11, 5, 9, 15, in: calendar)
        let suiteName = "DailyVerseProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = DailyVerseProvider(userDefaults: defaults)

        #expect(provider.verse(for: today, calendar: calendar).ref == DailyAnchorResolver.payload(for: today, calendar: calendar).ref)
    }

    @Test func dateTransitionAroundLocalMidnight() {
        let calendar = calendar("America/Los_Angeles")
        let beforeMidnight = date(2026, 3, 8, 23, 59, in: calendar)
        let afterMidnight = date(2026, 3, 9, 0, 1, in: calendar)

        #expect(DailyAnchorResolver.localDayKey(for: beforeMidnight, calendar: calendar) == "2026-03-08")
        #expect(DailyAnchorResolver.localDayKey(for: afterMidnight, calendar: calendar) == "2026-03-09")
        #expect(DailyAnchorResolver.anchor(for: beforeMidnight, calendar: calendar).ref != DailyAnchorResolver.anchor(for: afterMidnight, calendar: calendar).ref)
    }

    @Test func nonUTCTimeZoneUsesLocalDay() {
        let tokyo = calendar("Asia/Tokyo")
        let instant = ISO8601DateFormatter().date(from: "2026-01-01T15:30:00Z")!

        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: tokyo) == "2026-01-02")
    }

    @Test func timeZoneChangeCanMoveInstantIntoDifferentLocalDate() {
        let honolulu = calendar("Pacific/Honolulu")
        let kiritimati = calendar("Pacific/Kiritimati")
        let instant = ISO8601DateFormatter().date(from: "2026-07-16T10:30:00Z")!

        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: honolulu) == "2026-07-16")
        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: kiritimati) == "2026-07-17")
    }

    @Test func staleCachedPayloadFromYesterdayIsRejected() {
        let calendar = calendar("America/Chicago")
        let yesterday = date(2026, 7, 15, 12, 0, in: calendar)
        let today = date(2026, 7, 16, 12, 0, in: calendar)
        let stalePayload = DailyAnchorResolver.payload(for: yesterday, calendar: calendar)

        #expect(!DailyAnchorResolver.payload(stalePayload, matches: today, calendar: calendar))
    }

    @Test func offlineBehaviorUsesLocallyAvailableDailyAnchorData() {
        let calendar = calendar("America/Chicago")
        let today = date(2026, 7, 16, 12, 0, in: calendar)
        let payload = DailyAnchorResolver.payload(for: today, calendar: calendar)

        #expect(DailyAnchorResolver.payload(payload, matches: today, calendar: calendar))
        #expect(payload.ref == DailyAnchorResolver.anchor(for: today, calendar: calendar).ref)
    }
}

struct DailyDevotionalImplementationTests {
    private func calendar(_ identifier: String = "America/Chicago") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func validFirestoreData(overrides: [String: Any?] = [:]) -> [String: Any] {
        var data: [String: Any] = [
            "date": "2026-07-20",
            "title": "  Firebase Title  ",
            "verseReference": " Placeholder 1:1 ",
            "verseText": " Placeholder verse text. ",
            "body": " Placeholder body. ",
            "cta": " Lowercase CTA ",
            "imageURL": "https://example.com/image.jpg"
        ]

        for (key, value) in overrides {
            if let value {
                data[key] = value
            } else {
                data.removeValue(forKey: key)
            }
        }
        return data
    }

    @Test func validRequiredFieldsProduceFirebaseDevotionalAndTrimValues() {
        let cal = calendar()
        let fallbackDate = date(2026, 7, 20, in: cal)
        let devotional = DailyDevotionalService.mapFirestoreData(validFirestoreData(), id: "firebase-1", fallbackDate: fallbackDate, calendar: cal)

        #expect(devotional?.id == "firebase-1")
        #expect(devotional?.title == "Firebase Title")
        #expect(devotional?.verseReference == "Placeholder 1:1")
        #expect(devotional?.verseText == "Placeholder verse text.")
        #expect(devotional?.body == "Placeholder body.")
    }

    @Test func validHttpsImageURLMaps() {
        let devotional = DailyDevotionalService.mapFirestoreData(validFirestoreData(), id: "firebase-1", fallbackDate: Date())
        #expect(devotional?.imageURL?.absoluteString == "https://example.com/image.jpg")
    }

    @Test func missingAndBlankImageURLRemainNilWithoutRejectingDevotional() {
        for override in [nil, "", "   \n  "] as [String?] {
            var overrides: [String: Any?] = [:]
            overrides["imageURL"] = override
            let devotional = DailyDevotionalService.mapFirestoreData(validFirestoreData(overrides: overrides), id: UUID().uuidString, fallbackDate: Date())
            #expect(devotional != nil)
            #expect(devotional?.imageURL == nil)
        }
    }

    @Test func unsupportedImageURLValuesRemainNil() {
        let invalidValues = [
            "/relative/path.jpg",
            "gs://bucket/path.jpg",
            "http://example.com/image.jpg",
            "not a url",
            "https://"
        ]

        for value in invalidValues {
            let devotional = DailyDevotionalService.mapFirestoreData(
                validFirestoreData(overrides: ["imageURL": value]),
                id: value,
                fallbackDate: Date()
            )
            #expect(devotional != nil)
            #expect(devotional?.imageURL == nil)
        }
    }

    @Test func ctaCompatibilityUsesLowercaseThenUppercaseThenNil() {
        let lowercase = DailyDevotionalService.mapFirestoreData(
            validFirestoreData(overrides: ["cta": " lower ", "CTA": " upper "]),
            id: "lower",
            fallbackDate: Date()
        )
        #expect(lowercase?.cta == "lower")

        let uppercase = DailyDevotionalService.mapFirestoreData(
            validFirestoreData(overrides: ["cta": nil, "CTA": " upper "]),
            id: "upper",
            fallbackDate: Date()
        )
        #expect(uppercase?.cta == "upper")

        let missing = DailyDevotionalService.mapFirestoreData(
            validFirestoreData(overrides: ["cta": nil, "CTA": nil]),
            id: "missing",
            fallbackDate: Date()
        )
        #expect(missing != nil)
        #expect(missing?.cta == nil)
    }

    @Test func invalidRequiredFieldsRejectWholeFirebaseDocument() {
        let invalidOverrides: [[String: Any?]] = [
            ["title": nil],
            ["verseReference": "  \n  "],
            ["verseText": 42],
            ["body": ""]
        ]

        for overrides in invalidOverrides {
            let devotional = DailyDevotionalService.mapFirestoreData(
                validFirestoreData(overrides: overrides),
                id: UUID().uuidString,
                fallbackDate: Date()
            )
            #expect(devotional == nil)
        }
    }

    @Test func invalidFirebaseDocumentFallbackIsCompleteLocalDevotional() {
        let cal = calendar()
        let fallbackDate = date(2026, 7, 20, in: cal)
        let mapped = DailyDevotionalService.mapFirestoreData(
            validFirestoreData(overrides: ["body": nil]),
            id: "invalid",
            fallbackDate: fallbackDate,
            calendar: cal
        )
        let fallback = DailyDevotional.placeholder(for: fallbackDate)

        #expect(mapped == nil)
        #expect(fallback.id.hasPrefix("placeholder-"))
        #expect(!fallback.title.isEmpty)
        #expect(!fallback.verseReference.isEmpty)
        #expect(!fallback.verseText.isEmpty)
        #expect(!fallback.body.isEmpty)
    }

    @Test func julyTwentyDayKeyUsesLocalDateFormat() {
        let cal = calendar("America/Los_Angeles")
        let july20 = date(2026, 7, 20, 9, 30, in: cal)
        #expect(DailyDevotionalService.dayKey(for: july20, calendar: cal) == "2026-07-20")
        #expect(DailyDevotionalViewModel.dayKey(for: july20, calendar: cal) == "2026-07-20")
    }

    @MainActor
    @Test func refreshIfDayChangedFetchesOnlyWhenLocalDayChanges() async {
        let cal = calendar()
        var fetchCount = 0
        let vm = DailyDevotionalViewModel(calendar: cal) { completion in
            fetchCount += 1
            completion(DailyDevotional.placeholder(for: Date()))
        }

        vm.loadDevotionalIfNeeded(now: date(2026, 7, 19, in: cal))
        await Task.yield()
        #expect(fetchCount == 1)
        #expect(vm.loadedDayKey == "2026-07-19")

        vm.refreshIfDayChanged(now: date(2026, 7, 19, 18, 0, in: cal))
        await Task.yield()
        #expect(fetchCount == 1)

        vm.refreshIfDayChanged(now: date(2026, 7, 20, 0, 1, in: cal))
        await Task.yield()
        #expect(fetchCount == 2)
        #expect(vm.loadedDayKey == "2026-07-20")

        vm.refreshIfDayChanged(now: date(2026, 7, 20, 12, 0, in: cal))
        await Task.yield()
        #expect(fetchCount == 2)
    }

    @Test func storyBackgroundResolutionUsesRemoteImageOnLoaderSuccess() async {
        let image = TestImageLoader.sampleImage()
        let loader = TestImageLoader(result: image)
        let devotional = DailyDevotional(
            id: "remote",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/story.jpg")
        )

        let resolved = await DevotionalVerseStoryBackgroundResolver.resolve(
            devotional: devotional,
            fallbackAssetName: "SteadfastStory1",
            imageLoader: loader
        )

        #expect(resolved.fallbackAssetName == "SteadfastStory1")
        #expect(resolved.usesRemoteImage)
        #expect(loader.loadedURLs == [URL(string: "https://example.com/story.jpg")!])
    }

    @Test func storyBackgroundResolutionKeepsLocalAssetWhenMissingURLOrLoaderFails() async {
        let loader = TestImageLoader(result: nil)
        let missingURL = DailyDevotional(
            id: "missing-url",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: nil
        )
        let brokenURL = DailyDevotional(
            id: "broken-url",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/broken.jpg")
        )

        let missingResolved = await DevotionalVerseStoryBackgroundResolver.resolve(
            devotional: missingURL,
            fallbackAssetName: "SteadfastStory2",
            imageLoader: loader
        )
        let brokenResolved = await DevotionalVerseStoryBackgroundResolver.resolve(
            devotional: brokenURL,
            fallbackAssetName: "SteadfastStory2",
            imageLoader: loader
        )

        #expect(!missingResolved.usesRemoteImage)
        #expect(!brokenResolved.usesRemoteImage)
        #expect(missingResolved.fallbackAssetName == "SteadfastStory2")
        #expect(brokenResolved.fallbackAssetName == "SteadfastStory2")
    }

    @Test func localStoryAssetSelectionIsDeterministicForSameDate() {
        let cal = calendar()
        let day = date(2026, 7, 20, in: cal)
        let first = DevotionalVerseStoryAssets.backgroundName(for: day)
        let second = DevotionalVerseStoryAssets.backgroundName(for: day)
        #expect(first == second)
    }

    @Test func storyPresentationUsesLoadedDevotionalWhenAvailable() {
        let devotional = DailyDevotional(
            id: "loaded",
            date: Date(),
            title: "Loaded Title",
            verseReference: "Loaded Ref",
            verseText: "Loaded Verse",
            body: "Loaded Body",
            cta: nil,
            imageURL: nil
        )

        let presentation = DevotionalStoryPresentationResolver.presentation(for: devotional, now: Date())

        #expect(presentation.devotional.id == "loaded")
        #expect(presentation.devotional.verseText == "Loaded Verse")
        #expect(presentation.devotional.verseReference == "Loaded Ref")
    }

    @Test func storyPresentationUsesCompleteFallbackWhenNoDevotionalLoaded() {
        let cal = calendar()
        let now = date(2026, 7, 20, 8, 0, in: cal)
        let presentation = DevotionalStoryPresentationResolver.presentation(for: nil, now: now)

        #expect(presentation.devotional.id.hasPrefix("placeholder-"))
        #expect(!presentation.devotional.title.isEmpty)
        #expect(!presentation.devotional.verseText.isEmpty)
        #expect(!presentation.devotional.verseReference.isEmpty)
        #expect(!presentation.devotional.body.isEmpty)
        #expect(!presentation.background.usesRemoteImage)
    }

    @Test func storyPresentationPreloadsRemoteBackgroundBeforePresentation() async {
        let image = TestImageLoader.sampleImage()
        let loader = TestImageLoader(result: image)
        let devotional = DailyDevotional(
            id: "remote-presentation",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/story.jpg")
        )
        let initial = DevotionalStoryPresentationResolver.presentation(for: devotional)

        let prepared = await DevotionalStoryPresentationResolver.preloadRemoteBackground(
            for: initial,
            imageLoader: loader
        )

        #expect(prepared.devotional.id == devotional.id)
        #expect(prepared.background.usesRemoteImage)
        #expect(loader.loadedURLs == [devotional.imageURL!])
    }

    @Test func storyPresentationUsesFinalLocalBackgroundWhenRemotePreloadFails() async {
        let loader = TestImageLoader(result: nil)
        let devotional = DailyDevotional(
            id: "failed-remote-presentation",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/broken.jpg")
        )
        let initial = DevotionalStoryPresentationResolver.presentation(for: devotional)

        let prepared = await DevotionalStoryPresentationResolver.preloadRemoteBackground(
            for: initial,
            imageLoader: loader
        )

        #expect(!prepared.background.usesRemoteImage)
        #expect(prepared.background.fallbackAssetName == initial.background.fallbackAssetName)
    }

    @Test func initialStoryBackgroundIsLocalAssetWithoutImageURL() {
        let devotional = DailyDevotional(
            id: "local-background",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: nil
        )

        let snapshot = DevotionalVerseStoryBackgroundSnapshot.initial(for: devotional)

        #expect(!snapshot.usesRemoteImage)
        #expect(["SteadfastStory1", "SteadfastStory2"].contains(snapshot.fallbackAssetName))
    }

    @Test func initialStoryBackgroundIsLocalAssetBeforeRemoteImageLoads() {
        let devotional = DailyDevotional(
            id: "remote-background",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/story.jpg")
        )

        let snapshot = DevotionalVerseStoryBackgroundSnapshot.initial(for: devotional)

        #expect(!snapshot.usesRemoteImage)
        #expect(["SteadfastStory1", "SteadfastStory2"].contains(snapshot.fallbackAssetName))
    }

    @Test func cancellationStyleRemoteFailureRetainsLocalAssetSnapshot() async {
        let loader = TestImageLoader(result: nil)
        let devotional = DailyDevotional(
            id: "cancelled-load",
            date: Date(),
            title: "Title",
            verseReference: "Ref",
            verseText: "Verse",
            body: "Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/cancelled.jpg")
        )

        let resolved = await DevotionalVerseStoryBackgroundResolver.resolve(
            devotional: devotional,
            fallbackAssetName: "SteadfastStory1",
            imageLoader: loader
        )

        #expect(!resolved.usesRemoteImage)
        #expect(resolved.fallbackAssetName == "SteadfastStory1")
    }

    @Test func continueUsesCapturedDevotionalDespiteLaterViewModelChange() {
        let captured = DailyDevotional(
            id: "captured-story",
            date: Date(),
            title: "Captured Title",
            verseReference: "Captured Ref",
            verseText: "Captured Verse",
            body: "Captured Body",
            cta: nil,
            imageURL: nil
        )
        let later = DailyDevotional(
            id: "later-home-state",
            date: Date(),
            title: "Later Title",
            verseReference: "Later Ref",
            verseText: "Later Verse",
            body: "Later Body",
            cta: nil,
            imageURL: nil
        )

        let presentation = PresentedDevotionalStory(devotional: captured)
        let detailDevotional = presentation.devotional

        #expect(detailDevotional.id == "captured-story")
        #expect(later.id == "later-home-state")
        #expect(detailDevotional.id != later.id)
    }

    @MainActor
    @Test func shareRendererAcceptsCapturedDevotionalAndBackgroundSnapshot() {
        let devotional = DailyDevotional(
            id: "captured",
            date: Date(),
            title: "Captured Title",
            verseReference: "Captured Ref",
            verseText: "Captured Verse",
            body: "Captured Body",
            cta: nil,
            imageURL: URL(string: "https://example.com/story.jpg")
        )
        let background = DevotionalVerseStoryBackgroundSnapshot(
            fallbackAssetName: "SteadfastStory1",
            remoteImage: TestImageLoader.sampleImage()
        )

        _ = DevotionalVerseStoryRenderer.renderImage(devotional: devotional, background: background)
        #expect(background.usesRemoteImage)
        #expect(devotional.id == "captured")
    }

    @Test func sharePayloadRetainsAValidRenderedImage() {
        let image = TestImageLoader.sampleImage()

        let payload = SharePayload(image: image, fallbackText: "Fallback")

        #expect(payload.activityItems.count == 1)
        #expect(payload.activityItems.first as? UIImage === image)
    }

    @Test func sharePayloadUsesMeaningfulTextWhenRenderingFails() {
        let payload = SharePayload(image: nil, fallbackText: "  A completed Steadfast experience  ")

        #expect(payload.activityItems.count == 1)
        #expect(payload.activityItems.first as? String == "A completed Steadfast experience")
    }

    @Test func sharePayloadNeverContainsAnEmptyActivityItem() {
        let payload = SharePayload(image: nil, fallbackText: "   \n")

        #expect(payload.activityItems.count == 1)
        #expect(payload.activityItems.first as? String == "Shared from Steadfast")
    }
}

private final class TestImageLoader: DevotionalVerseRemoteImageLoading {
    private let result: UIImage?
    private(set) var loadedURLs: [URL] = []

    init(result: UIImage?) {
        self.result = result
    }

    func loadImage(from url: URL) async -> UIImage? {
        loadedURLs.append(url)
        return result
    }

    static func sampleImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
}
