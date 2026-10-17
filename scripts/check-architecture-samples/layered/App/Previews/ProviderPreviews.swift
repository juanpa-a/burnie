// expect: none
#if DEBUG
import BurnieApplication
import BurnieComponents
import BurnieInterface
import BurnieProviders
import SwiftUI

/// Previews read each provider's descriptor, never its bundle.
enum ProviderPreviews {
    static let descriptors = [ClaudeProvider.descriptor, CursorProvider.descriptor]
}
#endif
