//
//  Verse+Codable.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/6/25.
//

import Foundation

extension Verse: Codable {
    private enum CodingKeys: String, CodingKey {
        case ref, text, audioFile
        case breathIn, breathOut            // legacy (string cues or ints)
        case breatheIn = "breathInSecs"     // optional numeric durations
        case breatheOut = "breathOutSecs"
        case inhaleCue, exhaleCue           // explicit cue keys (future-proof)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.ref = try c.decode(String.self, forKey: .ref)
        self.text = (try? c.decode(String.self, forKey: .text)) ?? ""
        self.audioFile = try? c.decode(String.self, forKey: .audioFile)

        // explicit cues (if present)
        let cueIn  = try? c.decode(String.self, forKey: .inhaleCue)
        let cueOut = try? c.decode(String.self, forKey: .exhaleCue)

        // durations (if present as secs)
        let durIn  = try? c.decode(Int.self, forKey: .breatheIn)
        let durOut = try? c.decode(Int.self, forKey: .breatheOut)

        // legacy: breathIn/breathOut could be strings (cues) or ints (durations)
        let legacyInInt  = (try? c.decode(Int.self, forKey: .breathIn))
        let legacyOutInt = (try? c.decode(Int.self, forKey: .breathOut))
        let legacyInStr  = (try? c.decode(String.self, forKey: .breathIn))
        let legacyOutStr = (try? c.decode(String.self, forKey: .breathOut))

        // resolve cues
        self.inhaleCue = [cueIn, legacyInStr].compactMap {
            $0?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.first(where: { !$0.isEmpty })

        self.exhaleCue = [cueOut, legacyOutStr].compactMap {
            $0?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.first(where: { !$0.isEmpty })

        // resolve durations
        self.breathIn  = durIn  ?? legacyInInt
        self.breathOut = durOut ?? legacyOutInt
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(ref,  forKey: .ref)
        try c.encode(text, forKey: .text)
        if let audioFile { try c.encode(audioFile, forKey: .audioFile) }
        if let inhaleCue { try c.encode(inhaleCue, forKey: .breathIn) }   // legacy-friendly
        if let exhaleCue { try c.encode(exhaleCue, forKey: .breathOut) }  // legacy-friendly
        if let breathIn  { try c.encode(breathIn,  forKey: .breatheIn) }
        if let breathOut { try c.encode(breathOut, forKey: .breatheOut) }
    }
}
