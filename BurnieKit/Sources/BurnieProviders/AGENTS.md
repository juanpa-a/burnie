# BurnieProviders

Each provider turns its sources into parts: Claude Code (`Claude/`) and Cursor (`Cursor/`), with what they share in
`Shared/`. Sources are internal: nothing outside a provider's folder knows what it reads, how often, or in how many
calls. A provider's only public face is its entry point (`descriptor`, `bundle`) and its ports struct.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `P-*` in [6.1](../../../SPEC.md#61-rules-p-), Claude in
[6.2](../../../SPEC.md#62-claude), Cursor in [6.3](../../../SPEC.md#63-cursor).

- **P-1** Imports `Foundation`, `BurnieDomain`, `BurnieInterface` only; all I/O through ports.
- **P-2** A folder per provider; `Shared/` never mentions one.
- **P-3** One entry point per provider with exactly `descriptor` and `bundle(_:)`, plus its ports struct.
- **P-4** DTOs never leave their provider's folder; mappers are pure.
- **P-5** Memos only avoid repeated work, live in an `actor`, and persist only through `ProviderStorage`.
- **P-6** Each provider builds its HTTP client for its own hosts, and its process runner for its own executables.
- **P-7** Never refreshes, writes or rotates another app's credentials.
- **P-8** A provider's own issues are `.specific`, with copy in its descriptor.
- **P-9** Every DTO has a fixture with the real shape and invented values.
- **P-10** Shared code is extracted on the second use; duplication between providers is a defect.
