import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {

                    // Bible card at the top
                    // LibraryView.swift (inside the ScrollView’s LazyVStack, replace the old Bible card)
                    NavigationLink {
                        BibleTOCView()
                    } label: {
                        BibleHeroCard(
                            title: "Bible (KJV)",
                            subtitle: "Read & search the Word",
                            systemImage: "book.closed.fill",
                            imageName: "BibleCard",
                            height: 160   // ← tweak this to make it taller/shorter
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Saved devotionals entry (hero style)
                    NavigationLink {
                        SavedDevotionalsView()
                    } label: {
                        SavedDevotionalsHeroCard(
                            title: "Saved Devotionals",
                            subtitle: "Revisit your bookmarked devotionals",
                            imageName: "SavedDevotionalsCardImage",
                            height: 160 // match Bible card height
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // ⬇️ Add this header right above the packs
                    HStack(spacing: 8) {
                        //Image(systemName: "leaf.fill").foregroundStyle(Theme.accent)
                        Text("Verse Packs")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    
                    // Verse packs as spaced cards
                    ForEach(vm.library.packs) { pack in
                        NavigationLink(value: pack) {
                            LibraryPackCard(pack: pack)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: VersePack.self) { pack in
                VersePackDetail(pack: pack)
            }
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
    }
}

// MARK: - Cards

struct LibraryPackCard: View {
    let pack: VersePack

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hands.sparkles.fill")
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(pack.title)
                    .font(.headline)
                Text(pack.description)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(2)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.line)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
    }
}

struct LargeActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(Theme.inkSecondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.line)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
    }
}

struct SavedDevotionalsHeroCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    var height: CGFloat = 160

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
            } else {
                // TODO: Add asset named "SavedDevotionalsCardImage" for full effect
                Color(UIColor.systemGray5)
                    .frame(height: height)
            }

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.25), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bookmark.fill")
                    .font(.title3)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.9))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
