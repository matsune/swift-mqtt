import Foundation

public enum DecodeError: Error {
    case malformedData
    case malformedQoS
    case malformedPacketType
    case malformedConnAckReturnCode
    case malformedSubAckReturnCode
}

final class MQTTDecoder {
    func decode(data: Data) throws -> MQTTPacket {
        if data.isEmpty {
            throw DecodeError.malformedData
        }
        let packetType = try MQTTPacketType(packet: data[0] >> 4)
        let flags = data[0] & 0x0F
        let fixedHeader = FixedHeader(packetType: packetType, flags: flags)
        let remainLen = decodeRemainLen(data: data)
        // advance size of fixed header
        let body: Data
        if data.count > 2 {
            body = data.advanced(by: 2)[..<remainLen]
        } else {
            body = Data()
        }
        print(packetType)
        switch fixedHeader.packetType {
        case .connack:
            return try ConnAckPacket(fixedHeader: fixedHeader, data: body)
        case .pingresp:
            return PingRespPacket(fixedHeader: fixedHeader)
        case .publish:
            return try PublishPacket(fixedHeader: fixedHeader, data: body)
        case .puback:
            return try PubAckPacket(fixedHeader: fixedHeader, data: body)
        case .pubrec:
            return try PubRecPacket(fixedHeader: fixedHeader, data: body)
        case .pubcomp:
            return try PubCompPacket(fixedHeader: fixedHeader, data: body)
        case .suback:
            return try SubAckPacket(fixedHeader: fixedHeader, data: body)
        case .unsuback:
            return try UnsubAckPacket(fixedHeader: fixedHeader, data: data)
        default:
            fatalError()
        }
    }

    private func decodeRemainLen(data: Data) -> Int {
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
}
