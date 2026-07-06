import Flutter
import Security
import UIKit

enum KeychainReadResult {
    case value(String)
    case missing
    case unavailable(OSStatus)
}

protocol DeviceIdKeychainStore {
    func read(account: String, service: String?) -> KeychainReadResult
    func save(account: String, service: String, value: String) -> Bool
    func delete(account: String, service: String?) -> Bool
}

final class SystemDeviceIdKeychainStore: DeviceIdKeychainStore {
    func read(account: String, service: String?) -> KeychainReadResult {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let service {
            query[kSecAttrService as String] = service
        }

        var resultData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &resultData)

        if status == errSecItemNotFound {
            return .missing
        }
        guard status == errSecSuccess else {
            return .unavailable(status)
        }
        guard let data = resultData as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return .missing
        }

        return .value(value)
    }

    func save(account: String, service: String, value: String) -> Bool {
        guard !value.isEmpty, let data = value.data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }
        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var addQuery = query
        addQuery.merge(attributes) { _, new in new }
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    /// Deletes a Keychain item.
    /// - Parameters:
    ///   - account: The Keychain account identifier.
    ///   - service: The service scope. If `nil`, the query matches all items for this account broadly.
    ///     To target only legacy items created without a service, pass an empty string `""`.
    func delete(account: String, service: String?) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        if let service {
            query[kSecAttrService as String] = service
        }

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

public class PersistentDeviceIdPlugin: NSObject, FlutterPlugin {
    private static let account = "persistent_device_id.maeltoukap.me"
    private static let service = "persistent_device_id"

    private let keychainStore: DeviceIdKeychainStore
    private let idGenerator: () -> String

    public override init() {
        keychainStore = SystemDeviceIdKeychainStore()
        idGenerator = { UUID().uuidString }
        super.init()
    }

    init(
        keychainStore: DeviceIdKeychainStore,
        idGenerator: @escaping () -> String = { UUID().uuidString }
    ) {
        self.keychainStore = keychainStore
        self.idGenerator = idGenerator
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "persistent_device_id",
            binaryMessenger: registrar.messenger()
        )
        let instance = PersistentDeviceIdPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getDeviceId" {
            result(getOrCreateDeviceId())
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    /// Retrieves the persistent device ID from the Keychain, performing migration and cleanup.
    ///
    /// ## Migration & Cleanup Strategy:
    /// - **Pre-2.0.0 (Legacy)**: Stored without a service scope (`service: nil`). This defaulted to a
    ///   backup-eligible accessibility, causing the device ID to leak across physical devices via backup restores.
    /// - **2.0.0+ (Scoped)**: Stored under a scoped service (`persistent_device_id`) with `ThisDeviceOnly` accessibility.
    ///
    /// To resolve the leak, we must delete the legacy item. However, deleting with `service: nil` matches
    /// and deletes both legacy and scoped items. Setting `service: ""` (empty string) in the query specifically
    /// targets the legacy item (since it has no service key, defaulting to `""` in the database) without affecting
    /// the scoped item.
    ///
    /// We delete the legacy item in two places:
    /// 1. Immediately after successfully migrating the legacy ID to the scoped item.
    /// 2. On launch, if the scoped item already exists (cleans up legacy items for users upgrading from intermediate 2.x versions).
    func getOrCreateDeviceId() -> String? {
        switch keychainStore.read(account: Self.account, service: Self.service) {
        case let .value(existing):
            // Clean up the legacy item if it exists.
            _ = keychainStore.delete(account: Self.account, service: "")
            return existing
        case .unavailable:
            return nil
        case .missing:
            break
        }

        switch keychainStore.read(account: Self.account, service: nil) {
        case let .value(legacy):
            // Legacy entries were stored without a service. Save to scoped first.
            let saved = keychainStore.save(
                account: Self.account,
                service: Self.service,
                value: legacy
            )
            if saved {
                // Once safely migrated to the scoped item, delete the legacy item.
                _ = keychainStore.delete(account: Self.account, service: "")
            }
            return legacy
        case .unavailable:
            return nil
        case .missing:
            break
        }

        let generatedId = idGenerator()
        guard !generatedId.isEmpty else {
            return nil
        }

        return keychainStore.save(
            account: Self.account,
            service: Self.service,
            value: generatedId
        ) ? generatedId : nil
    }
}
