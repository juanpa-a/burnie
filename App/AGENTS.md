# App

Views and wiring only; no business logic.

- Views read only `UsageStore` (`ProviderState`, `DailyPoint`). Never a Claude or Cursor DTO.
- `UsageStore` is the only piece that changes state. `RefreshScheduler` decides when each source refreshes.
- Colors, typography, and measurements come from `Views/Tokens.swift`. No loose hex values or magic numbers in views.
- All visible text and its formatting (tokens, money, captions) comes from the `BurnieCore` formatters.
- Every `PreviewScenario` has a `#Preview` fed by `UsageStore.preview(...)`, which touches neither network nor disk.
