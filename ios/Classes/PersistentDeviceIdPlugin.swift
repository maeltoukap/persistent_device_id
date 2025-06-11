import Flutter
import UIKit
import Security

public class PersistentDeviceIdPlugin: NSObject, FlutterPlugin {
    static let key = "persistent_device_id.maeltoukap.me"

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
        if let existing = loadFromKeychain(key: Self.key) {
            return existing
        }

        let uuid = UUID().uuidString
        saveToKeychain(key: Self.key, value: uuid)
        return uuid
    }

    func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var resultData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &resultData)

        if status == errSecSuccess, let data = resultData as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }
}
