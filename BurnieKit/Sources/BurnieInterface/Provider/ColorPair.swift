import Foundation

/// A provider's accent for light and dark appearance; Components turns it into a color.
public struct ColorPair: Hashable, Sendable {
    public let light: RGB
    public let dark: RGB

    public init(light: RGB, dark: RGB) {
        self.light = light
        self.dark = dark
    }
}
