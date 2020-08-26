import Foundation

public protocol DataDecodable {
    init(data: Data) throws
}

public enum DecodeError: Error {
    case malformedData
}

func decode(data: Data) throws -> MQTTRecvPacket {
//    if data.isEmpty {
//        throw DecodeError.malformedData
//    }
//    guard let packetType = PacketType(rawValue: data[0] >> 4) else {
//        throw DecodeError.malformedData
//    }
//    let flags = data[0] & 0b1111
    let fixedHeader = try FixedHeader(data: data)
    let remainLen = try decodeRemainLen(data: data)
    // advance size of fixed header
    let body: Data
    if data.count > 2 {
        body = data.advanced(by: 2)[..<remainLen]
    } else {
        body = Data()
    }
//    guard body.count == remainLen else {
//        throw DecodeError.malformedData
//    }
    switch fixedHeader.packetType {
    case .connack:
        return try ConnAck(fixedHeader: fixedHeader, data: body)
    case .pingresp:
        return PingResp(fixedHeader: fixedHeader)
    case .publish:
        return Publish(fixedHeader: fixedHeader, data: body)
    case .puback:
        return try PubAck(fixedHeader: fixedHeader, data: body)
    case .pubrec:
        return try PubRec(fixedHeader: fixedHeader, data: body)
    case .pubcomp:
        return try PubComp(fixedHeader: fixedHeader, data: body)
    case .suback:
        return try SubAck(fixedHeader: fixedHeader, data: body)
    case .unsuback:
        return try UnsubAck(fixedHeader: fixedHeader, data: data)
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
