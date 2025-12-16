import SwiftUI

extension HomeView {
    @ViewBuilder var navShortcuts: some View {
        NavigationLink("Thought Reframe") { ThoughtReframeView() }
    }
}