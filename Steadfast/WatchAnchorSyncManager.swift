import Foundation
import OSLog
import WatchConnectivity

final class WatchAnchorSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchAnchorSyncManager()

    private let logger = Logger(subsystem: "ashatune.Steadfast", category: "WatchAnchorSync")
    private let payloadKey = "anchorPayload"
    private let encoder = JSONEncoder()
    private var pendingPayload: AnchorOfDayPayload?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            logger.info("WatchConnectivity is not supported on this device.")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sync(_ payload: AnchorOfDayPayload) {
        pendingPayload = payload
        activateIfNeeded()
        sendPendingPayloadIfPossible()
    }

    private func sendPendingPayloadIfPossible() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let payload = pendingPayload else { return }
        guard let data = try? encoder.encode(payload) else {
            logger.error("Unable to encode anchor payload for Watch sync.")
            return
        }

        let message = [payloadKey: data]
        let session = WCSession.default

        do {
            try session.updateApplicationContext(message)
        } catch {
            logger.error("Unable to update Watch application context: \(error.localizedDescription, privacy: .public)")
        }

        session.transferUserInfo(message)
        pendingPayload = nil
        logger.info("Queued anchor payload for Watch sync: \(payload.ref, privacy: .public)")
    }

    private func activateIfNeeded() {
        guard WCSession.isSupported(), WCSession.default.activationState == .notActivated else { return }
        activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("WatchConnectivity activation failed: \(error.localizedDescription, privacy: .public)")
        } else {
            logger.info("WatchConnectivity activated with state \(activationState.rawValue).")
            sendPendingPayloadIfPossible()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
