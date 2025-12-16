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
            Section("Trigger") { TextField("e.g., waiting for lab results", text: $trigger) }
            Section("Automatic Thought") { TextField("What flashed through your mind?", text: $thought) }
            Section("Feeling (0–100%)") { TextField("e.g., fear 80%", text: $feeling) }
            Section("Evidence FOR / AGAINST") {
                TextField("For", text: $evidenceFor)
                TextField("Against", text: $evidenceAgainst)
            }
            Section("Scripture Truth") { TextField("e.g., Psalm 73:26 — God is my strength", text: $scriptureTruth) }
            Section("Reframed Thought") { Text(newThought).foregroundStyle(.secondary) }
        }
        .navigationTitle("Thought Reframe")
    }
}