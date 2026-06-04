import SwiftUI

struct ThoughtReframeView: View {
    @State private var trigger = ""
    @State private var thought = ""
    @State private var feeling = ""
    @State private var evidenceFor = ""
    @State private var evidenceAgainst = ""
    @State private var scriptureTruth = ""
    
    var newThought: String {
        guard !scriptureTruth.isEmpty else { return "A steadier thought will appear here." }
        return "Given \(scriptureTruth), a kinder, truer thought might be: …"
    }
    
    var body: some View {
        Form {
            Section { TextField("e.g., waiting for lab results", text: $trigger) } header: { Text("Trigger").foregroundStyle(Theme.sectionTitle) }
            Section { TextField("What flashed through your mind?", text: $thought) } header: { Text("Automatic Thought").foregroundStyle(Theme.sectionTitle) }
            Section { TextField("e.g., fear 80%", text: $feeling) } header: { Text("Feeling (0–100%)").foregroundStyle(Theme.sectionTitle) }
            Section {
                TextField("For", text: $evidenceFor)
                TextField("Against", text: $evidenceAgainst)
            } header: {
                Text("Evidence FOR / AGAINST")
                    .foregroundStyle(Theme.sectionTitle)
            }
            Section { TextField("e.g., Psalm 73:26 — God is my strength", text: $scriptureTruth) } header: { Text("Scripture Truth").foregroundStyle(Theme.sectionTitle) }
            Section { Text(newThought).foregroundStyle(.secondary) } header: { Text("Reframed Thought").foregroundStyle(Theme.sectionTitle) }
        }
        .navigationTitle("Thought Reframe")
    }
}