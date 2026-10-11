import Foundation

/// Where the Cursor desktop app keeps its session. Paths live only here.
public struct CursorPaths: Sendable {
    public let home: URL

    public init(home: URL) {
        self.home = home
    }

    public var stateDatabase: URL {
        home.appending(path: "Library/Application Support/Cursor/User/globalStorage/state.vscdb")
    }
}
