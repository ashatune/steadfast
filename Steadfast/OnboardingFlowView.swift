import SwiftUI

/// The short, benefit-led introduction shown on a user's first launch.
struct OnboardingFlowView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("didCompleteOnboardingMeditation") private var didCompleteOnboardingMeditation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    private let pages = OnboardingPage.all

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingPalette.pageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $selectedPage) {
                        welcomePage(availableHeight: geometry.size.height)
                            .tag(0)

                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(
                                page: page,
                                availableHeight: geometry.size.height
                            )
                            .tag(index + 1)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedPage)

                    OnboardingPageIndicator(
                        pageCount: 4,
                        selectedPage: selectedPage
                    )
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                    navigationControls
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16))
                }
                .padding(.top, max(geometry.safeAreaInsets.top, 8))
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func welcomePage(availableHeight: CGFloat) -> some View {
        OnboardingPageContainer(
            availableHeight: availableHeight,
            artwork: {
                BreathingIconCircle(
                    size: min(max(availableHeight * 0.25, 150), 230),
                    animated: !reduceMotion,
                    minScale: reduceMotion ? 1 : 0.86,
                    maxScale: reduceMotion ? 1 : 1.12,
                    breathDuration: 4.5
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("A calming breathing circle, gently expanding and contracting")
            },
            title: "Welcome to Steadfast",
            description: "Find peace, reconnect with God, and feel supported throughout your day."
        )
    }

    private var navigationControls: some View {
        HStack(spacing: 18) {
            Button("Skip", action: completeOnboarding)
                .font(.headline)
                .foregroundStyle(OnboardingPalette.secondaryText)
                .frame(minWidth: 64, minHeight: 52)
                .accessibilityLabel("Skip onboarding")

            Spacer(minLength: 0)

            Button(selectedPage == 3 ? "Get Started" : "Next") {
                if selectedPage == 3 {
                    completeOnboarding()
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                        selectedPage += 1
                    }
                }
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .frame(maxWidth: 210)
            .accessibilityLabel(selectedPage == 3 ? "Get Started" : "Next")
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private func completeOnboarding() {
        // This legacy value described the old required intro practice. Clearing it
        // ensures that completing or skipping this preview cannot leave practice
        // state behind. RootView observes the existing completion preference.
        didCompleteOnboardingMeditation = false
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPage: Identifiable {
    let imageName: String
    let imageAccessibilityLabel: String
    let title: String
    let description: String

    var id: String { imageName }

    static let all = [
        OnboardingPage(
            imageName: "onboardingSlide2Image",
            imageAccessibilityLabel: "Calm Now breathing, prayer, and grounding exercises",
            title: "Find calm when you need it most",
            description: "Use quick breathing, prayer, and grounding exercises whenever stress feels overwhelming."
        ),
        OnboardingPage(
            imageName: "onboardingSlide3Image",
            imageAccessibilityLabel: "A peaceful daily faith routine",
            title: "Make peace part of your daily rhythm",
            description: "Begin your day with scripture, guided meditation, prayer, and meaningful reflection."
        ),
        OnboardingPage(
            imageName: "onboardingSlide4Image",
            imageAccessibilityLabel: "Steadfast on iPhone, a Home Screen widget, and Apple Watch",
            title: "Carry peace wherever you go",
            description: "Keep peace close with your iPhone, Home Screen widget, or Apple Watch."
        )
    ]
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let availableHeight: CGFloat

    var body: some View {
        OnboardingPageContainer(
            availableHeight: availableHeight,
            artwork: {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 430)
                    .accessibilityLabel(page.imageAccessibilityLabel)
            },
            title: page.title,
            description: page.description
        )
    }
}

private struct OnboardingPageContainer<Artwork: View>: View {
    let availableHeight: CGFloat
    @ViewBuilder let artwork: () -> Artwork
    let title: String
    let description: String

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                artwork()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: min(max(availableHeight * 0.38, 190), 340))
                    .padding(.horizontal, 28)

                Spacer(minLength: 24)

                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(OnboardingPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.body)
                    .foregroundStyle(OnboardingPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(availableHeight - 155, 430))
        }
        .scrollIndicators(.hidden)
    }
}

private struct OnboardingPageIndicator: View {
    let pageCount: Int
    let selectedPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == selectedPage ? Theme.accent : Theme.accent.opacity(0.22))
                    .frame(width: index == selectedPage ? 22 : 7, height: 7)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Page \(selectedPage + 1) of \(pageCount)")
    }
}

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
