import Foundation

public protocol DataEncodable {
    func encode() -> Data
}

func encodeRemainLen(_ length: Int) -> Data {
    var data = Data(capacity: 4)
    var x = length
    var encodedByte: UInt8 = 0
    repeat {
        encodedByte = UInt8(x % 128)
        x /= 128
        if x > 0 {
            encodedByte |= 128
        }
        data.append(encodedByte)
    } while x > 0
    return data
}

