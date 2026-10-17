# BurnieDomain

The internal language as types: values and total functions, no I/O, no async, no time source. Every concept here is in
the glossary of [`SPEC.md`](../../../SPEC.md#2-glossary), with the same name.

The rules' text lives only in `SPEC.md`: `G-*` in [3.3](../../../SPEC.md#33-rules-for-every-module-g-), `D-*` in
[4.1](../../../SPEC.md#41-rules-d-), the laws in [4.4](../../../SPEC.md#44-laws), the wire format in
[12](../../../SPEC.md#12-persistence-contract).

- **D-1** Only `import Foundation`, and from it only values and pure functions.
- **D-2** No `class`, `actor`, `async`, `Task` or `static var`.
- **D-3** No clock, time zone, locale, file system, network, process, defaults or bundle.
- **D-4** Every public type is `Sendable` and `Equatable`; persisted ones are `Codable` with a tested wire format.
- **D-5** Total functions: an invalid input is unrepresentable or mapped to a documented value.
- **D-6** No user-visible strings.
- **D-7** Every algebraic operation has its laws in SPEC 4.4 and a property test.
- **D-8** Nothing provider-specific.
