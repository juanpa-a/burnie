import Foundation

/// A value the app remembers between launches. In the app it lives in `UserDefaults`; previews use `fixed`.
struct Setting<Value> {
    let load: () -> Value
    let save: (Value) -> Void

    /// For previews: always `value`, persists nothing.
    static func fixed(_ value: Value) -> Setting {
        Setting(load: { value }, save: { _ in })
    }
}
