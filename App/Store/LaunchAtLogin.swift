import os
import ServiceManagement

/// "Launch at login" with `SMAppService.mainApp`, no helper app.
@MainActor @Observable
final class LaunchAtLogin {
    private(set) var isEnabled = false

    /// Read whenever the providers screen appears: the user can also change it from System Settings.
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            Logger(subsystem: "dev.juanpa.burnie", category: "app").error("Launch at login: \(error.localizedDescription, privacy: .public)")
        }
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        refresh()
    }
}
