import Foundation

public protocol DataDecodable {
    init(data: Data) throws
}

public enum DecodeError: Error {
    case malformedData
}

func decode(data: Data) throws -> MQTTRecvPacket {
    if data.isEmpty {
        throw DecodeError.malformedData
    }
    guard let packetType = PacketType(rawValue: data[0] >> 4) else {
        throw DecodeError.malformedData
    }
    switch packetType {
    case .connack:
        return try ConnAck(data: data)
    case .pingresp:
        return try PingResp(data: data)
    case .puback:
        return try PubAck(data: data)
    case .pubrec:
        return try PubRec(data: data)
    case .pubcomp:
        return try PubComp(data: data)
    default:
        fatalError()
    }
}

func decodeRemainLen(data: Data) throws -> Int {
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
