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
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: Circle())

                Text("You’re all set!").font(.title3).bold().foregroundColor(.white)
                Text("Thanks for doing your first exercise.\nWelcome to Steadfast.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))

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
