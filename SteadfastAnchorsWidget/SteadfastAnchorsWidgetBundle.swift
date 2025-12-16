//
//  SteadfastAnchorsWidgetBundle.swift
//  SteadfastAnchorsWidget
//
//  Created by Asha Redmon on 10/21/25.
//

import WidgetKit
import SwiftUI

@main
struct SteadfastAnchorsWidgetBundle: WidgetBundle {
    var body: some Widget {
        AnchorWidget()
        SteadfastAnchorsWidgetControl()
        SteadfastAnchorsWidgetLiveActivity()
    }
}
