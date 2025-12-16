//
//  RemoteConfigService.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/5/25.
//

import Foundation
import Combine

struct AppConfig: Decodable {
    let minVersion: String
    let softMinVersion: String
    let storeUrl: String
    let flags: Flags
    struct Flags: Decodable {
        let reframe_enabled: Bool
        let premium_enabled: Bool
    }
}

final class RemoteConfigService: ObservableObject {
    @Published var config: AppConfig?
    private let urlString = "https://ashatune.github.io/steadfast-config/config.json"
    private let cacheKey = "app_config_cache"

    func fetch() async {
        guard let url = URL(string: urlString) else { return }
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let cfg = try JSONDecoder().decode(AppConfig.self, from: data)
            await MainActor.run {
                self.config = cfg
            }
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            // fallback to cached config if available
            if let data = UserDefaults.standard.data(forKey: cacheKey),
               let cfg = try? JSONDecoder().decode(AppConfig.self, from: data) {
                await MainActor.run { self.config = cfg }
            }
        }
    }
}
