import XCTest
@testable import swift_mqtt

final class swift_mqttTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_mqtt().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
