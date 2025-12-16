import SwiftUI

struct CenterStage<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geo in
            VStack { content() }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}
