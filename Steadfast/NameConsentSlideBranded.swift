//
//  NameConsentSlideBranded.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

import SwiftUI

struct NameConsentSlideBranded: View {
    @Binding var displayName: String
    @Binding var hasAcceptedTerms: Bool
    var onContinue: () -> Void

    @State private var showTerms = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Let’s personalize your experience")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(OnboardingPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    Text("What’s your name?")
                        .font(.callout)
                        .foregroundStyle(OnboardingPalette.secondaryText)

                    TextField("Your first name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .onSubmit {
                            continueIfValid()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(OnboardingPalette.controlFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(OnboardingPalette.subtleStroke)
                        )
                        .foregroundStyle(OnboardingPalette.primaryText)
                        .tint(Theme.accent)
                        .frame(maxWidth: 420)

                    Button("Continue") {
                        continueIfValid()
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.6)
                    .frame(maxWidth: 420)
                }

                VStack(spacing: 10) {
                    Button {
                        showTerms = true
                    } label: {
                        Text("View Terms & Conditions")
                            .underline()
                            .font(.footnote)
                            .foregroundColor(Theme.accent)
                    }
                    .tint(Theme.accent)
                    .sheet(isPresented: $showTerms) { TermsSheetBranded() }

                    Toggle(isOn: $hasAcceptedTerms) {
                        Text("I accept the Terms & Conditions")
                            .font(.subheadline)
                            .foregroundStyle(OnboardingPalette.primaryText)
                    }
                    .toggleStyle(.switch)
                    .tint(Theme.accent)
                    .frame(maxWidth: 420)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.async {
                isNameFocused = true
            }
        }
    }

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasAcceptedTerms
    }

    private func continueIfValid() {
        guard canContinue else { return }
        displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        isNameFocused = false
        onContinue()
    }
}

// Terms (branded)
struct TermsSheetBranded: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        BrandBackground {
            ScrollView {
                GlassCard(maxWidth: .infinity) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Steadfast — Terms & Conditions").font(.title3).bold().foregroundStyle(OnboardingPalette.primaryText)

                        Group {
                            Text("1. Agreement to Terms").bold() + Text(" By using Steadfast, you agree to these Terms & Conditions and our policies. If you do not agree, please discontinue use.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("2. Not Medical or Mental Health Advice").bold() +
                            Text(" Steadfast provides spiritual meditations and breathing exercises for general well-being. It is not a medical, mental-health, or crisis service. Consult your physician before starting any exercises. In an emergency, call 911 or your local emergency number.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("3. No Professional Relationship").bold() +
                            Text(" Use of the app does not create a doctor-patient, therapist-client, or pastoral-care relationship.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("4. Subscriptions & Refunds").bold() +
                            Text(" Steadfast may offer paid subscriptions in the future. Pricing, features, and availability may change. Refunds are at our sole discretion and may not be available in all cases or regions.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("5. Content & Acceptable Use").bold() +
                            Text(" Do not misuse the app or infringe intellectual property. Content may change or be removed without notice.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("6. Limitation of Liability").bold() +
                            Text(" To the maximum extent permitted by law, Steadfast and its owners are not liable for direct or indirect damages arising from your use of the app.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("7. Privacy").bold() +
                            Text(" We process limited personal information to operate the app. See our Privacy Notice (if available).")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("8. Age Requirements").bold() +
                            Text(" You must meet your region’s age of digital consent to use the app.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("9. Changes to Terms").bold() +
                            Text(" We may update these terms at any time. Continued use after changes constitutes acceptance.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)

                        Group {
                            Text("10. Contact").bold() +
                            Text(" For questions about these terms, contact the Steadfast team.")
                        }.foregroundStyle(OnboardingPalette.secondaryText)
                    }
                }
                .padding(.vertical, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .buttonStyle(SubtleButtonStyle())
                }
            }
        }
    }
}
