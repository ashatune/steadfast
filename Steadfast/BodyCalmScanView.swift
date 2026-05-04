import SwiftUI

struct BodyCalmScanView: View {
    var body: some View {
        SOSExerciseView(
            title: "Body Calm Scan",
            subtitle: "Let your body soften and settle.",
            audioResource: "SteadfastSOSbodyScan",
            audioExtension: "wav"
        )
    }
}
