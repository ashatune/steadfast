//
//  NameConsentSlideBranded.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

// NameConsentSlideBranded.swift
import SwiftUI

struct NameConsentSlideBranded: View {
    @Binding var displayName: String
    @Binding var hasAcceptedTerms: Bool
    @State private var showTerms = false

    var body: some View {
        GlassCard(maxWidth: .infinity) {
            VStack(spacing: 16) {
                Text("Let’s personalize your experience")
                    .font(.title3).bold().foregroundStyle(.primary)

                VStack(spacing: 10) {
                    Text("What’s your name?")
                        .font(.callout).foregroundStyle(.secondary)

                    TextField("Your first name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .onSubmit {
                            displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .padding(.vertical, 10).padding(.horizontal, 12)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line.opacity(0.4)))
                        .foregroundStyle(.primary)
                        .tint(Theme.accent)
                        .frame(maxWidth: 320)
                }

                // Terms link + toggle
                VStack(spacing: 8) {
                    Button {
                        showTerms = true
                    } label: {
                        Text("View Terms & Conditions")
                            .underline().font(.footnote).foregroundColor(Theme.accent)
                    }
                    .tint(Theme.accent)
                    .sheet(isPresented: $showTerms) { TermsSheetBranded() }

                    Toggle(isOn: $hasAcceptedTerms) {
                        Text("I accept the Terms & Conditions")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .toggleStyle(.switch)
                    .tint(Theme.accent)
                    .frame(maxWidth: 360)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
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
                        Text("Steadfast — Terms & Conditions").font(.title3).bold().foregroundStyle(.primary)

                        Group {
                            Text("1. Agreement to Terms").bold() + Text(" By using Steadfast, you agree to these Terms & Conditions and our policies. If you do not agree, please discontinue use.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("2. Not Medical or Mental Health Advice").bold() +
                            Text(" Steadfast provides spiritual meditations and breathing exercises for general well-being. It is not a medical, mental-health, or crisis service. Consult your physician before starting any exercises. In an emergency, call 911 or your local emergency number.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("3. No Professional Relationship").bold() +
                            Text(" Use of the app does not create a doctor-patient, therapist-client, or pastoral-care relationship.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("4. Subscriptions & Refunds").bold() +
                            Text(" Steadfast may offer paid subscriptions in the future. Pricing, features, and availability may change. Refunds are at our sole discretion and may not be available in all cases or regions.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("5. Content & Acceptable Use").bold() +
                            Text(" Do not misuse the app or infringe intellectual property. Content may change or be removed without notice.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("6. Limitation of Liability").bold() +
                            Text(" To the maximum extent permitted by law, Steadfast and its owners are not liable for direct or indirect damages arising from your use of the app.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("7. Privacy").bold() +
                            Text(" We process limited personal information to operate the app. See our Privacy Notice (if available).")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("8. Age Requirements").bold() +
                            Text(" You must meet your region’s age of digital consent to use the app.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("9. Changes to Terms").bold() +
                            Text(" We may update these terms at any time. Continued use after changes constitutes acceptance.")
                        }.foregroundStyle(.secondary)

                        Group {
                            Text("10. Contact").bold() +
                            Text(" For questions about these terms, contact the Steadfast team.")
                        }.foregroundStyle(.secondary)
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
