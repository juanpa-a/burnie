# BurnieInterface

The contract between the UI, the runtime and the providers: ports (what providers and Infra implement), the provider
contract, use cases (what the UI calls), the app state the views render, and presentation (every user-visible text).
Types, protocols and pure presentation; no state.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `I-*` in [5.1](../../../SPEC.md#51-rules-i-), the ports in
[5.2](../../../SPEC.md#52-ports), the provider contract in [5.3](../../../SPEC.md#53-provider-contract).

- **I-1** Imports only `Foundation` and `BurnieDomain`.
- **I-2** No shared mutable state: no `class`, `actor`, `static var` or global `var`.
- **I-3** A type identical to a domain type is deleted; the domain type is used.
- **I-4** Every capability is an optional field of `ProviderCapabilities`; every feature, of `SnapshotFeatures`.
- **I-5** Ports are the minimum an adapter must do and never expose macOS or Foundation networking types.
- **I-6** Use cases are what the UI calls; ports are what providers and Infra implement.
- **I-7** All copy lives in `Presentation/`: English, sentence case, tested for the exact text.
