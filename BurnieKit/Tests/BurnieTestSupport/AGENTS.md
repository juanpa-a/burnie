# BurnieTestSupport

What the test targets share: `FixedClock`, the port fakes, fixture loading and `Gen`, the seeded generator for
property tests. A regular target that only test targets link, never a product. It imports only `Foundation` and
`BurnieCore`, never `Testing` or `@testable`, so everything another target uses is `public`. Fixtures stay in each
test target's resources; `Fixture` takes that target's bundle.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `T-*` in [16.3](../../../SPEC.md#163-test-strategy-per-module),
`Gen` in [16.4](../../../SPEC.md#164-property-tests).

- **G-4** One top-level type per file, named like the file; extensions are `Type+Topic.swift`.
- **G-11** `@unchecked Sendable` only in Infra and test code, with a comment naming the lock that serializes the state.
- **T-1** Swift Testing only.
- **T-2** One test file per type under test, `<Type>Tests.swift`.
- **T-3** A test that pins a catalog behavior starts its name with the B-ID.
- **T-4** No real time and no real network; real disk only in Infra tests.
- **T-5** No sleeping, polling or retries.
- **T-6** Fixtures keep the real shape with invented values.
- **T-7** Persistence fixtures are never edited; a format change adds a new one.
- **T-8** Property tests run over `Gen.seeds(200)` and print the seed in the expectation message.
- **T-9** Component render tests build their values here, never from `App/Previews`.
- **T-10** A test target `@testable import`s only the module it tests.
