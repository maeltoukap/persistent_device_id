import Flutter
import XCTest

@testable import persistent_device_id

class RunnerTests: XCTestCase {
  func testGetDeviceIdReturnsStableValue() {
    let plugin = PersistentDeviceIdPlugin()
    let call = FlutterMethodCall(methodName: "getDeviceId", arguments: [])

    var firstResult: String?
    let firstExpectation = expectation(description: "first result block must be called")
    plugin.handle(call) { result in
      firstResult = result as? String
      firstExpectation.fulfill()
    }
    wait(for: [firstExpectation], timeout: 1)

    var secondResult: String?
    let secondExpectation = expectation(description: "second result block must be called")
    plugin.handle(call) { result in
      secondResult = result as? String
      secondExpectation.fulfill()
    }
    wait(for: [secondExpectation], timeout: 1)

    XCTAssertFalse(firstResult?.isEmpty ?? true)
    XCTAssertEqual(firstResult, secondResult)
  }
}
