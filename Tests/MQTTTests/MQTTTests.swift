import XCTest
@testable import MQTT

final class MQTTTests: XCTestCase {
    func testEncodeRemainLen() {
        XCTAssert(encodeRemainLen(0) == Data([0]))
        XCTAssert(encodeRemainLen(127) == Data([0x7F]))
        XCTAssert(encodeRemainLen(128) == Data([0x80, 0x01]))
        XCTAssert(encodeRemainLen(16_383) == Data([0xFF, 0x7F]))
        XCTAssert(encodeRemainLen(16_384) == Data([0x80, 0x80, 0x01]))
        XCTAssert(encodeRemainLen(2_097_151) == Data([0xFF, 0xFF, 0x7F]))
        XCTAssert(encodeRemainLen(2_097_152) == Data([0x80, 0x80, 0x80, 0x01]))
        XCTAssert(encodeRemainLen(268_435_455) == Data([0xFF, 0xFF, 0xFF, 0x7F]))
    }

    func testDecodeRemainingLength() {
        var data = Data([0x00])
        XCTAssert(try decodeRemainLen(data: &data) == 0)
        data = Data([0x7F])
        XCTAssert(try decodeRemainLen(data: &data) == 127)
        data = Data([0x80, 0x01])
        XCTAssert(try decodeRemainLen(data: &data) == 128)
        data = Data([0xFF, 0x7F])
        XCTAssert(try decodeRemainLen(data: &data) == 16_383)
        data = Data([0x80, 0x80, 0x01])
        XCTAssert(try decodeRemainLen(data: &data) == 16_384)
        data = Data([0xFF, 0xFF, 0x7F])
        XCTAssert(try decodeRemainLen(data: &data) == 2_097_151)
        data = Data([0x80, 0x80, 0x80, 0x01])
        XCTAssert(try decodeRemainLen(data: &data) == 2_097_152)
        data = Data([0xFF, 0xFF, 0xFF, 0x7F])
        XCTAssert(try decodeRemainLen(data: &data) == 268_435_455)
    }

    static var allTests = [
        ("testEncodeRemainLen", testEncodeRemainLen),
        ("testDecodeRemainingLength", testDecodeRemainingLength),
    ]
}
