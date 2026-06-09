import Security
import XCTest

@testable import persistent_device_id

final class RunnerTests: XCTestCase {
    func testReturnsExistingScopedId() {
        let store = MockKeychainStore(
            scopedResult: .value("scoped-id"),
            legacyResult: .missing
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "scoped-id")
        XCTAssertTrue(store.savedValues.isEmpty)
    }

    func testReturnsLegacyIdWhenMigrationSucceeds() {
        let store = MockKeychainStore(
            scopedResult: .missing,
            legacyResult: .value("legacy-id"),
            saveResult: true
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "legacy-id")
        XCTAssertEqual(store.savedValues, ["legacy-id"])
    }

    func testPreservesLegacyIdWhenMigrationWriteFails() {
        let store = MockKeychainStore(
            scopedResult: .missing,
            legacyResult: .value("legacy-id"),
            saveResult: false
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "legacy-id")
    }

    func testGeneratesIdAfterMissingOrCorruptedValues() {
        let store = MockKeychainStore(
            scopedResult: .missing,
            legacyResult: .missing,
            saveResult: true
        )
        let plugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id" }
        )

        XCTAssertEqual(plugin.getOrCreateDeviceId(), "generated-id")
        XCTAssertEqual(store.savedValues, ["generated-id"])
    }

    func testReturnsNilWhenScopedKeychainIsUnavailable() {
        let store = MockKeychainStore(
            scopedResult: .unavailable(errSecNotAvailable),
            legacyResult: .missing
        )
        let plugin = PersistentDeviceIdPlugin(keychainStore: store)

        XCTAssertNil(plugin.getOrCreateDeviceId())
        XCTAssertTrue(store.savedValues.isEmpty)
    }

    func testReturnsNilWhenGeneratedIdCannotBePersisted() {
        let store = MockKeychainStore(
            scopedResult: .missing,
            legacyResult: .missing,
            saveResult: false
        )
        let plugin = PersistentDeviceIdPlugin(
            keychainStore: store,
            idGenerator: { "generated-id" }
        )

        XCTAssertNil(plugin.getOrCreateDeviceId())
    }
}

private final class MockKeychainStore: DeviceIdKeychainStore {
    private let scopedResult: KeychainReadResult
    private let legacyResult: KeychainReadResult
    private let saveResult: Bool

    private(set) var savedValues: [String] = []

    init(
        scopedResult: KeychainReadResult,
        legacyResult: KeychainReadResult,
        saveResult: Bool = true
    ) {
        self.scopedResult = scopedResult
        self.legacyResult = legacyResult
        self.saveResult = saveResult
    }

    func read(account: String, service: String?) -> KeychainReadResult {
        service == nil ? legacyResult : scopedResult
    }

    func save(account: String, service: String, value: String) -> Bool {
        savedValues.append(value)
        return saveResult
    }
}
