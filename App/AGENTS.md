# App

The app target: views that read `AppModel` and wire components to use cases, the composition root that builds
everything, and the previews. No business logic.

The rules' text lives only in [`SPEC.md`](../SPEC.md): `G-*` in [3.3](../SPEC.md#33-rules-for-every-module-g-), `V-*` in
[10.1](../SPEC.md#101-rules-v-), `C-*` in [9.1](../SPEC.md#91-rules-c-) (views follow C-4 and C-5 too).

- **V-1** Views read `AppModel.state` and `AppModel.clock` and call `AppModel.useCases`; nothing else from Application.
- **V-2** No business logic: select, lay out and wire. `if let` on a capability or feature is fine; branching on a
  provider is not (G-5).
- **V-3** Only `Composition/` imports `BurnieProviders` and `BurnieInfra`; `Previews/` may import `BurnieProviders` to
  read each provider's `descriptor`.
- **V-4** Previews build an `AppState` and `AppModel.preview(_:clock:)`; every scenario of SPEC 16.7 has one.
- **V-5** AppKit only for what SwiftUI can't do: window placement, the template menu bar image.
- **C-4, C-5** Colors, fonts and measurements from `DesignTokens`; text from `Copy` or the descriptors.
