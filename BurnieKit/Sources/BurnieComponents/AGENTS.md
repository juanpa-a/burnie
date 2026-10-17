# BurnieComponents

SwiftUI pieces that take values and closures and know nothing about the app model, a provider or an adapter: meters,
rows, buttons, the week chart, the menu bar icon, and the design tokens they all draw with.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `C-*` in [9.1](../../../SPEC.md#91-rules-c-).

- **C-1** Imports `SwiftUI`, `BurnieDomain` and `BurnieInterface` only.
- **C-2** Inputs are values and closures: no app types in the environment, no `AppModel`, no use cases by name.
- **C-3** Only local UI state (`@State` for hover, spinning, a button in flight).
- **C-4** Colors, fonts and measurements come from `DesignTokens`; a provider's color from its descriptor.
- **C-5** No literal user-visible text: it comes in as a parameter or from `Copy`.
- **C-6** Every component has a `#Preview` from `PreviewValues` and a render smoke test.
- **C-7** Every icon-only control has an accessibility label.
