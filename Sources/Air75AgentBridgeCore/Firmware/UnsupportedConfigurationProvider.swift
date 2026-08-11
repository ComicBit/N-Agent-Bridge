import Foundation

public final class UnsupportedConfigurationProvider: KeyboardConfigurationProvider, @unchecked Sendable {
    public enum ConfigurationError: LocalizedError {
        case protocolUnavailable
        public var errorDescription: String? { "The NuPhyIO onboard-profile protocol is not public; the keyboard was not modified." }
    }

    public init() {}
    public func readCurrentProfile(for device: DeviceSnapshot) async throws -> Data { throw ConfigurationError.protocolUnavailable }
    public func writeProfile(_ data: Data, to device: DeviceSnapshot) async throws { throw ConfigurationError.protocolUnavailable }
}
