import XCTest
@testable import MQTT

final class swift_mqttTests: XCTestCase {
    func testEncodeRemainingLength() {
        XCTAssert(encode(remainingLength: 0) == Data([0]))
        XCTAssert(encode(remainingLength: 127) == Data([0x7F]))
        XCTAssert(encode(remainingLength: 128) == Data([0x80, 0x01]))
        XCTAssert(encode(remainingLength: 16_383) == Data([0xFF, 0x7F]))
        XCTAssert(encode(remainingLength: 16_384) == Data([0x80, 0x80, 0x01]))
        XCTAssert(encode(remainingLength: 2_097_151) == Data([0xFF, 0xFF, 0x7F]))
        XCTAssert(encode(remainingLength: 2_097_152) == Data([0x80, 0x80, 0x80, 0x01]))
        XCTAssert(encode(remainingLength: 268_435_455) == Data([0xFF, 0xFF, 0xFF, 0x7F]))
    }

    func testDecodeRemainingLength() {
        XCTAssert(try decode(remainingLength: Data([0x00, 0x00])) == 0)
        XCTAssert(try decode(remainingLength: Data([0x00, 0x7F])) == 127)
        XCTAssert(try decode(remainingLength: Data([0x00, 0x80, 0x01])) == 128)
        XCTAssert(try decode(remainingLength: Data([0x00, 0xFF, 0x7F])) == 16_383)
        XCTAssert(try decode(remainingLength: Data([0x00, 0x80, 0x80, 0x01])) == 16_384)
        XCTAssert(try decode(remainingLength: Data([0x00, 0xFF, 0xFF, 0x7F])) == 2_097_151)
        XCTAssert(try decode(remainingLength: Data([0x00, 0x80, 0x80, 0x80, 0x01])) == 2_097_152)
        XCTAssert(try decode(remainingLength: Data([0x00, 0xFF, 0xFF, 0xFF, 0x7F])) == 268_435_455)
    }

    static var allTests = [
        ("testEncodeRemainingLength", testEncodeRemainingLength),
        ("testDecodeRemainingLength", testDecodeRemainingLength),
    ]
}
