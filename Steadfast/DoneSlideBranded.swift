//
//  DoneSlideBranded.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

import SwiftUI

struct DoneSlideBranded: View {
    let onEnter: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(14)
                    .background(Theme.accent.opacity(0.08), in: Circle())

                Text("You’re all set!")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(OnboardingPalette.primaryText)

                Text("Thanks for doing your first exercise.\nWelcome to Steadfast.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(OnboardingPalette.secondaryText)

                Button {
                    onEnter()
                } label: {
                    Text("Enter Steadfast")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.top, 8)
                .frame(maxWidth: 420)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
