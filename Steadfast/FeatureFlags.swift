//
//  FeatureFlags.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/5/25.
//

import Foundation
import Combine

final class FeatureFlags: ObservableObject {
    @Published var reframeEnabled = false
    @Published var premiumEnabled = false

    func update(from config: AppConfig) {
        reframeEnabled = config.flags.reframe_enabled
        premiumEnabled = config.flags.premium_enabled
    }
}
