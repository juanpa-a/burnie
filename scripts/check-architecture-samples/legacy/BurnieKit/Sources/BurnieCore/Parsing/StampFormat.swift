// expect: none
/// Runs of X in a date format or a temporary-folder template aren't G-8 markers.
enum StampFormat {
    static let zoned = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    static let folderTemplate = "burnie.XXXXXX"
}
