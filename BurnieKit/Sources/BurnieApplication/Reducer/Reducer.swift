import Foundation

/// `(RuntimeState, Event) -> (RuntimeState, [Effect])`: the only place state changes. Pure and synchronous (A-2).
enum Reducer {
    static func reduce(_ state: RuntimeState, _ event: Event) -> (RuntimeState, [Effect]) {
        var next = state
        next.today = event.today
        next.timeZone = event.timeZone
        let effects = next.apply(event.kind, now: event.now)
        return (next, effects)
    }
}
