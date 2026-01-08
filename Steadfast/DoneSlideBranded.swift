//
//  DoneSlideBranded.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

// DoneSlideBranded.swift
import SwiftUI

struct DoneSlideBranded: View {
    let onEnter: () -> Void
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(14)
                    .background(Theme.accent.opacity(0.08), in: Circle())

                Text("You’re all set!").font(.title3).bold().foregroundStyle(.primary)
                Text("Thanks for doing your first exercise.\nWelcome to Steadfast.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button {
                    onEnter()
                } label: {
                    Text("Enter Steadfast").fontWeight(.semibold)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
        }
    }
}
