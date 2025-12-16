#if false
import SwiftUI

struct LegacyReframeFlowView: View {
    @State private var step: Int = 1
    @State private var thought: String = ""
    @State private var distortion: String = ""
    @State private var challenge: String = ""
    @State private var reframe: String = ""
    
    private let totalSteps = 5
    
    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: Double(step), total: Double(totalSteps))
                .padding()
            
            Spacer()
            
            // Step content
            Group {
                switch step {
                case 1:
                    CaptureThoughtView(thought: $thought)
                case 2:
                    IdentifyDistortionView(distortion: $distortion)
                case 3:
                    ChallengeView(challenge: $challenge)
                case 4:
                    ReframeView(reframe: $reframe)
                case 5:
                    AnchorView()
                default:
                    Text("All done!")
                }
            }
            .padding()
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if step > 1 {
                    Button("Back") { step -= 1 }
                        .padding()
                }
                Spacer()
                if step < totalSteps {
                    Button("Next") { step += 1 }
                        .padding()
                } else {
                    Button("Finish") {
                        // Save to journal or dismiss
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut, value: step)
    }
}

struct CaptureThoughtView: View {
    @Binding var thought: String
    var body: some View {
        VStack {
            Text("Step 1: What’s the thought on your mind?")
                .font(.headline)
            TextEditor(text: $thought)
                .frame(height: 150)
                .border(Color.gray.opacity(0.3))
        }
    }
}

struct IdentifyDistortionView: View {
    @Binding var distortion: String
    var body: some View {
        VStack {
            Text("Step 2: Can you identify the thinking pattern?")
                .font(.headline)
            TextField("e.g., Catastrophizing", text: $distortion)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ChallengeView: View {
    @Binding var challenge: String
    var body: some View {
        VStack {
            Text("Step 3: What evidence supports this thought? What evidence goes against it?")
                .font(.headline)
            TextEditor(text: $challenge)
                .frame(height: 150)
                .border(Color.gray.opacity(0.3))
        }
    }
}

struct ReframeView: View {
    @Binding var reframe: String
    var body: some View {
        VStack {
            Text("Step 4: Reframe it into a healthier thought.")
                .font(.headline)
            TextEditor(text: $reframe)
                .frame(height: 150)
                .border(Color.gray.opacity(0.3))
        }
    }
}

struct AnchorView: View {
    var body: some View {
        VStack {
            Text("Step 5: Anchor")
                .font(.headline)
            Text("Take this new perspective with you. Remember: You are safe, loved, and capable.")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#endif

