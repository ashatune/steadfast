import Foundation
import OSLog
import WatchConnectivity

struct WatchAnchorPayload: Codable, Equatable {
    let id: String
    let ref: String
    let text: String
    let inhale: String
    let exhale: String
    let anchorDate: Date
    let lastUpdated: Date

    static func fallback(anchorDate: Date = Date()) -> WatchAnchorPayload {
        WatchAnchorPayload(
            id: "Psalm 46:10",
            ref: "Psalm 46:10",
            text: "Be still, and know that I am God.",
            inhale: "Be still",
            exhale: "Know that I am God",
            anchorDate: Calendar.current.startOfDay(for: anchorDate),
            lastUpdated: Date()
        )
    }
}

final class WatchAnchorStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchAnchorStore()

    @Published private(set) var anchor: WatchAnchorPayload

    private let logger = Logger(subsystem: "ashatune.Steadfast.watchkitapp", category: "AnchorStore")
    private let defaultsKey = "watch_anchor_of_day_payload"
    private let payloadKey = "anchorPayload"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private override init() {
        anchor = Self.loadStoredAnchor() ?? .fallback()
        super.init()
        activateConnectivity()
    }

    var todaysAnchor: WatchAnchorPayload {
        guard Calendar.current.isDateInToday(anchor.anchorDate) else {
            return .fallback()
        }
        return anchor
    }

    func refreshFromStoredPayload() {
        guard let stored = Self.loadStoredAnchor() else { return }
        anchor = stored
    }

    private func activateConnectivity() {
        guard WCSession.isSupported() else {
            logger.info("WatchConnectivity is not supported on this watch.")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private static func loadStoredAnchor() -> WatchAnchorPayload? {
        guard let data = UserDefaults.standard.data(forKey: "watch_anchor_of_day_payload") else { return nil }
        return try? JSONDecoder().decode(WatchAnchorPayload.self, from: data)
    }

    private func save(_ payload: WatchAnchorPayload) {
        guard let data = try? encoder.encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        DispatchQueue.main.async {
            self.anchor = payload
        }
    }

    private func handlePayloadData(_ data: Data) {
        guard let payload = try? decoder.decode(WatchAnchorPayload.self, from: data) else {
            logger.error("Unable to decode anchor payload received from iPhone.")
            return
        }
        save(payload)
        logger.info("Received anchor payload from iPhone: \(payload.ref, privacy: .public)")
    }

    private func handleMessage(_ message: [String: Any]) {
        if let data = message[payloadKey] as? Data {
            handlePayloadData(data)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("WatchConnectivity activation failed: \(error.localizedDescription, privacy: .public)")
        } else {
            logger.info("WatchConnectivity activated with state \(activationState.rawValue).")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleMessage(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleMessage(userInfo)
    }
}
