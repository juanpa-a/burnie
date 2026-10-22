import BurnieInterface
import Foundation
import os
import ServiceManagement

/// `LoginItem` over `SMAppService.mainApp`, with no helper app.
@MainActor
public struct SMAppLoginItem: LoginItem {
    public init() {}

    public func status() -> LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        default: .disabled
        }
    }

    public func set(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            Logger(subsystem: OSDiagnosticsLog.subsystem, category: "app").error("Launch at login: \(error.localizedDescription, privacy: .private)")
        }
    }

    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
