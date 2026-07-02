import Security
import XCTest

@testable import persistent_device_id

final class RunnerTests: XCTestCase {
    func testReturnsExistingScopedId() {
        let store = MockKeychainStore(initialScopedValue: "scoped-id")
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "scoped-id")
        XCTAssertEqual(store.savedValues, [])
    }

    func testMigratesLegacyIdWithoutLosingItOnNextLaunch() {
        let store = MockKeychainStore(initialLegacyValue: "legacy-id")
        let firstLaunchPlugin = PersistentDeviceIdPlugin(keychainStore: store)
        let secondLaunchPlugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(firstLaunchPlugin.getOrCreateDeviceId(), "legacy-id")
        XCTAssertEqual(secondLaunchPlugin.getOrCreateDeviceId(), "legacy-id")
        XCTAssertEqual(store.savedValues, ["legacy-id"])
        XCTAssertEqual(store.scopedValue, "legacy-id")
        XCTAssertEqual(store.legacyValue, "legacy-id")
        XCTAssertEqual(store.deletedLegacyCount, 0)
    }

    func testPreservesLegacyIdWhenMigrationWriteFails() {
        let store = MockKeychainStore(
            initialLegacyValue: "legacy-id",
            saveResult: false
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "legacy-id")
        XCTAssertNil(store.scopedValue)
        XCTAssertEqual(store.deletedLegacyCount, 0)
    }

    func testGeneratesIdAfterMissingOrCorruptedValues() {
        let store = MockKeychainStore(saveResult: true)
        let plugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id" }
        )

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "generated-id")
        XCTAssertEqual(store.savedValues, ["generated-id"])
    }

    func testReturnsNilWhenScopedKeychainIsUnavailable() {
        let store = MockKeychainStore(
            scopedReadResultOverride: .unavailable(errSecNotAvailable)
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertNil(plugin.getOrCreateDeviceId())
        XCTAssertEqual(store.savedValues, [])
    }

    func testReturnsNilWhenGeneratedIdCannotBePersisted() {
        let store = MockKeychainStore(saveResult: false)
        let plugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id" }
        )

        XCTAssertNil(plugin.getOrCreateDeviceId())
    }

    func testBroadLegacyDeleteQueryWouldRemoveBothLegacyAndScopedItems() {
        let account = "persistent_device_id.tests.\(UUID().uuidString)"
        let scopedService = "persistent_device_id.tests.scoped"
        let store = SystemDeviceIdKeychainStore()

        addLegacyKeychainItem(account: account, value: "legacy-id")
        XCTAssertTrue(store.save(account: account, service: scopedService, value: "scoped-id"))

        defer {
            deleteKeychainItems(account: account, service: nil)
            deleteKeychainItems(account: account, service: scopedService)
        }

        guard case let .value(legacy) = store.read(account: account, service: nil) else {
            return XCTFail("Expected to read the legacy keychain item")
        }
        XCTAssertEqual(legacy, "legacy-id")

        let broadDeleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        XCTAssertEqual(SecItemDelete(broadDeleteQuery as CFDictionary), errSecSuccess)

        if case .missing = store.read(account: account, service: scopedService) {
            // Expected: the broad query removes the new scoped item too.
        } else {
            XCTFail("Expected broad account-only deletion to remove the scoped item")
        }

        if case .missing = store.read(account: account, service: nil) {
            return
        }
        XCTFail("Expected broad account-only deletion to remove the legacy item")
    }

    func testSystemKeychainMigrationPreservesIdAcrossTwoLaunches() {
        let store = SystemDeviceIdKeychainStore()

        deleteKeychainItems(account: pluginAccount, service: nil)
        deleteKeychainItems(account: pluginAccount, service: pluginService)
        addLegacyKeychainItem(account: pluginAccount, value: "legacy-id")

        defer {
            deleteKeychainItems(account: pluginAccount, service: nil)
            deleteKeychainItems(account: pluginAccount, service: pluginService)
        }

        let firstLaunchPlugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id-should-not-be-used" }
        )
        let secondLaunchPlugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id-should-not-be-used" }
        )

        XCTAssertEqual(firstLaunchPlugin.getOrCreateDeviceId(), "legacy-id")
        XCTAssertEqual(secondLaunchPlugin.getOrCreateDeviceId(), "legacy-id")

        guard case let .value(scoped) = store.read(account: pluginAccount, service: pluginService) else {
            return XCTFail("Expected migrated scoped keychain item to exist after first launch")
        }
        XCTAssertEqual(scoped, "legacy-id")

        guard case let .value(legacy) = store.read(account: pluginAccount, service: nil) else {
            return XCTFail("Expected legacy keychain item to remain readable after safe migration")
        }
        XCTAssertEqual(legacy, "legacy-id")
    }
}

private final class MockKeychainStore: DeviceIdKeychainStore {
    private let saveResult: Bool
    private let scopedReadResultOverride: KeychainReadResult?
    private let legacyReadResultOverride: KeychainReadResult?

    private var storedValues: [String?: String] = [:]
    private(set) var savedValues: [String] = []
    private(set) var deletedLegacyCount = 0
    var scopedValue: String? { storedValues[MockKeychainStore.scopedService] }
    var legacyValue: String? { storedValues[nil] }

    private static let scopedService = "persistent_device_id"
    init(
        initialScopedValue: String? = nil,
        initialLegacyValue: String? = nil,
        scopedReadResultOverride: KeychainReadResult? = nil,
        legacyReadResultOverride: KeychainReadResult? = nil,
        saveResult: Bool = true
    ) {
        self.saveResult = saveResult
        self.scopedReadResultOverride = scopedReadResultOverride
        self.legacyReadResultOverride = legacyReadResultOverride

        if let initialScopedValue {
            storedValues[MockKeychainStore.scopedService] = initialScopedValue
        }
        if let initialLegacyValue {
            storedValues[nil] = initialLegacyValue
        }
    }

    func read(account: String, service: String?) -> KeychainReadResult {
        if let override = service == nil ? legacyReadResultOverride : scopedReadResultOverride {
            return override
        }

        guard let value = storedValues[service], !value.isEmpty else {
            return .missing
        }
        return .value(value)
    }

    func save(account: String, service: String, value: String) -> Bool {
        savedValues.append(value)
        guard saveResult else {
            return false
        }
        storedValues[service] = value
        return saveResult
    }

    func delete(account: String, service: String?) -> Bool {
        if service == nil {
            deletedLegacyCount += 1
            // Matches the real regression: a query without service filters wipes
            // both the legacy item and any newly scoped item for the same account.
        }
        if service == nil {
            storedValues.removeAll()
        } else {
            storedValues.removeValue(forKey: service)
        }
        return true
    }
}

private let pluginAccount = "persistent_device_id.maeltoukap.me"
private let pluginService = "persistent_device_id"

private func addLegacyKeychainItem(account: String, value: String) {
    deleteKeychainItems(account: account, service: nil)

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        kSecValueData as String: Data(value.utf8)
    ]
    XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecSuccess)
}

private func deleteKeychainItems(account: String, service: String?) {
    var query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account
    ]
    if let service {
        query[kSecAttrService as String] = service
    }

    let status = SecItemDelete(query as CFDictionary)
    XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound)
}
