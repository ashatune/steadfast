//
//  ReviewPromptView.swift
//  Steadfast
//
//  Created by Asha Redmon on 12/3/25.
//

import SwiftUI

struct ReviewPromptView: View {
    var onRateNow: () -> Void
    var onLater: () -> Void
    var onNoThanks: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enjoying Steadfast?")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("If Steadfast has helped you feel calmer and stay anchored in God, would you take a moment to leave a review?")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: onRateNow) {
                    Text("Yes, I’d love to leave a review")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)   // matches your styling
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button(action: onLater) {
                    Text("Maybe later")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                }

                Button(role: .cancel, action: onNoThanks) {
                    Text("No thanks")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .presentationDetents([.fraction(0.35), .medium])
    }
}
