import Flutter
import Security
import UIKit

public class PersistentDeviceIdPlugin: NSObject, FlutterPlugin {
    private static let account = "persistent_device_id.maeltoukap.me"
    private static let service = "persistent_device_id"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "persistent_device_id", binaryMessenger: registrar.messenger())
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

    func getOrCreateDeviceId() -> String {
        if let existing = loadFromKeychain(account: Self.account, service: Self.service) {
            return existing
        }

        if let legacy = loadLegacyKeychainValue(account: Self.account) {
            saveToKeychain(account: Self.account, service: Self.service, value: legacy)
            return legacy
        }

        let uuid = UUID().uuidString
        saveToKeychain(account: Self.account, service: Self.service, value: uuid)
        return uuid
    }

    private func loadFromKeychain(account: String, service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        return loadString(query: query)
    }

    private func loadLegacyKeychainValue(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        return loadString(query: query)
    }

    private func loadString(query: [String: Any]) -> String? {
        var resultData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &resultData)

        guard status == errSecSuccess, let data = resultData as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func saveToKeychain(account: String, service: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
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

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
}
