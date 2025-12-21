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

                    // Saved devotionals entry
                    NavigationLink {
                        SavedDevotionalsView()
                    } label: {
                        LargeActionCard(
                            title: "Saved Devotionals",
                            subtitle: "Revisit your bookmarked devotionals",
                            systemImage: "bookmark.fill"
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
