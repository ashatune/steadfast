import SwiftUI

struct ProfileSheetView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    // Onboarding/AppStorage name (used by HomeView greeting)
    @AppStorage("displayName") private var storedDisplayName = ""

    @State private var firstName: String = ""
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var hasBirthdate = false   // toggle so birthdate is optional

    private var saveDisabled: Bool { firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        Form {
            Section("Your Info") {
                TextField("First name", text: $firstName)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)

                Toggle("Add birthdate", isOn: $hasBirthdate)

                if hasBirthdate {
                    DatePicker("Birthdate",
                               selection: $birthdate,
                               in: dateRange,
                               displayedComponents: .date)
                }
            }

            Section {
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(saveDisabled)

                Button("Cancel", role: .cancel) { dismiss() }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Prefer VM value; if empty, fall back to the stored onboarding name
            let vmName = vm.profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let stored = storedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
            firstName = vmName.isEmpty ? stored : vmName

            if let d = vm.profileBirthdate {
                birthdate = d
                hasBirthdate = true
            } else {
                hasBirthdate = false
            }
        }
    }

    private var dateRange: ClosedRange<Date> {
        let cal = Calendar.current
        let min = cal.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? Date(timeIntervalSince1970: 0)
        let max = Date()
        return min...max
    }

    private func save() {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Keep both sources of truth in sync:
        vm.profileFirstName = trimmed                 // used across the app
        storedDisplayName = trimmed                   // used by HomeView greeting (@AppStorage)

        vm.profileBirthdate = hasBirthdate ? birthdate : nil
        dismiss()
    }
}
