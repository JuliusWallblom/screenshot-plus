import SwiftUI

struct PreferencesView: View {
    @State private var launchAtLogin: Bool = LaunchAtLoginService.shared.isEnabled
    @State private var autoCheckUpdates: Bool = UpdateService.shared.autoCheckEnabled

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if newValue {
                            LaunchAtLoginService.shared.enable()
                        } else {
                            LaunchAtLoginService.shared.disable()
                        }
                    }
            }

            Section {
                Toggle("Check for Updates Automatically", isOn: $autoCheckUpdates)
                    .onChange(of: autoCheckUpdates) { _, newValue in
                        UpdateService.shared.autoCheckEnabled = newValue
                    }

                Button("Check for Updates Now") {
                    UpdateService.shared.checkForUpdates(silent: false)
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppConfig.version)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 200)
        .onAppear {
            // Refresh state in case it changed externally
            launchAtLogin = LaunchAtLoginService.shared.isEnabled
            autoCheckUpdates = UpdateService.shared.autoCheckEnabled
        }
    }
}
