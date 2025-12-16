//
//  Versioning.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/5/25.
//

import Foundation

func isOutdated(_ current: String, comparedTo required: String) -> Bool {
    func parts(_ s: String) -> [Int] { s.split(separator: ".").map { Int($0) ?? 0 } }
    let a = parts(current), b = parts(required)
    for i in 0..<max(a.count, b.count) {
        let x = i < a.count ? a[i] : 0
        let y = i < b.count ? b[i] : 0
        if x < y { return true }
        if x > y { return false }
    }
    return false
}
