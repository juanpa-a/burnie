// expect: D-3
import Foundation

/// Checks the disk from inside Domain.
public enum HistoryFile {
    public static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
