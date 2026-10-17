import AppKit
import BurnieApplication
import BurnieComponents
import SwiftUI

/// Switches between the usage and providers screens inside the same window.
struct RootView: View {
    private enum Route {
        case usage, providers
    }

    @Environment(AppModel.self) private var model
    @State private var route = Route.usage
    @State private var placement = PopoverPlacement()

    var body: some View {
        ZStack {
            switch route {
            case .usage:
                UsageView(onOpenProviders: { show(.providers) })
                    .transition(.opacity)
            case .providers:
                ProvidersView(onBack: { show(.usage) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: DesignTokens.Metrics.popoverWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(DesignTokens.Palette.pop)
        .background(WindowReader { placement.keepCentered($0) })
        // Opening the popover = whichever comes first: onAppear or the window becoming key (B-39).
        .onAppear(perform: popoverOpened)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            popoverOpened()
        }
    }

    private func show(_ destination: Route) {
        withAnimation(DesignTokens.Motion.screenChange) { route = destination }
    }

    /// Every opening starts on the usage screen (B-39).
    private func popoverOpened() {
        route = .usage
        model.useCases.openPopover()
    }
}
