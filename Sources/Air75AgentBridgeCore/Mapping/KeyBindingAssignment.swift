import Foundation

public enum KeyBindingAssignment {
    /// Assigns one action to a verified keyboard usage. If that physical key
    /// already owns another action, the two bindings swap so no action is
    /// silently lost and no duplicate physical trigger is persisted.
    public static func assigning(
        bindingAt index: Int,
        usagePage: Int,
        usage: Int,
        in bindings: [KeyBinding],
        signalLightLayoutID: String?
    ) -> [KeyBinding]? {
        guard bindings.indices.contains(index),
              KeyBinding.isSupportedInputSource(usagePage: usagePage, usage: usage) else {
            return nil
        }
        var updated = bindings
        let previous = updated[index]
        if let duplicate = updated.indices.first(where: {
            $0 != index
                && updated[$0].usagePage == usagePage
                && updated[$0].usage == usage
        }) {
            updated[duplicate].usagePage = previous.usagePage
            updated[duplicate].usage = previous.usage
            updated[duplicate].signalLightIndex = previous.signalLightIndex
        }
        updated[index].usagePage = usagePage
        updated[index].usage = usage
        // The installed board profile makes physical F1-F12 report F13-F24,
        // while the RGB matrix remains indexed by physical key position.
        let physicalUsage = (0x68...0x73).contains(usage)
            ? usage - (0x68 - 0x3A) : usage
        updated[index].signalLightIndex = SignalLightLayout.index(
            layoutID: signalLightLayoutID,
            usagePage: usagePage,
            usage: physicalUsage
        )
        return updated
    }
}
