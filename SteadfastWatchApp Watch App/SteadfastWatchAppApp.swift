//
//  SteadfastWatchAppApp.swift
//  SteadfastWatchApp Watch App
//
//  Created by Asha Redmon on 11/6/25.
//

import OSLog
import SwiftUI

@main
struct SteadfastWatchApp: App {
    private let logger = Logger(subsystem: "ashatune.Steadfast.watchkitapp", category: "App")

    init() {
        logger.info("Watch app initializing.")
    }

    var body: some Scene {
        WindowGroup {
            WatchMeditationFlowView()
                .onAppear {
                    logger.info("Watch app window group appeared.")
                }
        }
    }
}
