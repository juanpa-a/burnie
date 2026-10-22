import Foundation

/// Where the Cursor desktop app keeps its session. Paths live only here.
struct CursorPaths: Sendable {
    let home: URL

    var stateDatabase: URL {
        home.appending(path: "Library/Application Support/Cursor/User/globalStorage/state.vscdb")
    }
}
