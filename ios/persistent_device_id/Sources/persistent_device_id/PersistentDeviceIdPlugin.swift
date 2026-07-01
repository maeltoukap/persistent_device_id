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

    func getOrCreateDeviceId() -> String? {
        switch keychainStore.read(account: Self.account, service: Self.service) {
        case let .value(existing):
            return existing
        case .unavailable:
            return nil
        case .missing:
            break
        }

        switch keychainStore.read(account: Self.account, service: nil) {
        case let .value(legacy):
            if keychainStore.save(
                account: Self.account,
                service: Self.service,
                value: legacy
            ) {
                _ = keychainStore.delete(account: Self.account, service: nil)
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
