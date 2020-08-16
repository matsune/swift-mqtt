import Foundation

enum DecodeError: Error {
    case invalidData
    case invalidPacketType
}

func decode(data: Data) throws -> some MQTTRecvPacket {
    if data.isEmpty {
        throw DecodeError.invalidData
    }
    guard let packetType = PacketType(rawValue: data[0] >> 4) else {
        throw DecodeError.invalidPacketType
    }
    switch packetType {
    case .connack:
        return try ConnackPacket(data: data)
    default:
        throw DecodeError.invalidPacketType
    }
}

func encode(remainingLength length: Int) -> Data {
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

func decode(remainingLength data: Data) throws -> Int {
    var multiplier = 1
    var value = 0
    var encodedByte: UInt8 = 0
    var cursor = 0
    repeat {
        cursor += 1
        encodedByte = data[cursor]
        value += (Int(encodedByte) & 127) * multiplier
        multiplier *= 128
        if multiplier > 128 * 128 * 128 {
            break
        }
    } while (encodedByte & 128) != 0
    return value
}
