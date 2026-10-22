# BurnieApplication

The runtime: the only owner of state that changes over time, the scheduler, and the implementation of the use cases.
A pure reducer over `RuntimeState`, one interpreter that performs its effects through the ports, and `AppModel`, the
observable value the views read. Its only public types are `AppModel` and `AppEnvironment`.

The rules' text lives only in [`SPEC.md`](../../../SPEC.md): `G-*` in
[3.3](../../../SPEC.md#33-rules-for-every-module-g-), `A-*` in [7.1](../../../SPEC.md#71-rules-a-), the runtime state
in [7.2](../../../SPEC.md#72-runtime-state), events and effects in [7.3](../../../SPEC.md#73-events-and-effects).

- **A-1** Only `AppModel` and `AppEnvironment` are public.
- **A-2** State changes only in the reducer, pure and synchronous.
- **A-3** One interpreter performs the effects and feeds results back as events; nothing else calls a port.
- **A-4** No scheduler actor: job state lives in the reducer, scheduling decisions are pure functions.
- **A-5** Time only from `Clock`, waiting only through `Sleeper`; every event carries `now` and `today`.
- **A-6** `AppState` is derived by a pure function of `RuntimeState`.
- **A-7** Every Application behavior of SPEC section 11 has a test that names its ID.
