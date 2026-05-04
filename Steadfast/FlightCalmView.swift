import SwiftUI

struct FlightCalmView: View {
    var body: some View {
        SOSExerciseView(
            title: "Flight Calm",
            subtitle: "A steadying meditation for moments of flight anxiety.",
            audioResource: "personalPlaneCalmMeditation",
            audioExtension: "wav"
        )
    }
}
