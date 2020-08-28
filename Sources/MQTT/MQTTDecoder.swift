import Foundation

final class MQTTDecoder {
    func decode(data: inout Data) throws -> MQTTPacket {
        guard data.hasSize(1) else {
            throw DecodeError.malformedData
        }
        let byte1 = data.read1ByteInt()
        let packetType = try MQTTPacketType(packet: byte1 >> 4)
        let flags = byte1 & 0x0F
        let fixedHeader = FixedHeader(packetType: packetType, flags: flags)
        let remainLen = try decodeRemainLen(data: &data)
        guard data.count == remainLen else {
            throw DecodeError.malformedData
        }
        switch fixedHeader.packetType {
        case .connack:
            return try ConnAckPacket(fixedHeader: fixedHeader, data: &data)
        case .pingresp:
            return PingRespPacket(fixedHeader: fixedHeader)
        case .publish:
            return try PublishPacket(fixedHeader: fixedHeader, data: &data)
        case .puback:
            return try PubAckPacket(fixedHeader: fixedHeader, data: &data)
        case .pubrec:
            return try PubRecPacket(fixedHeader: fixedHeader, data: &data)
        case .pubcomp:
            return try PubCompPacket(fixedHeader: fixedHeader, data: &data)
        case .suback:
            return try SubAckPacket(fixedHeader: fixedHeader, data: &data)
        case .unsuback:
            return try UnsubAckPacket(fixedHeader: fixedHeader, data: &data)
        default:
            throw DecodeError.malformedData
        }
    }
}

internal func decodeRemainLen(data: inout Data) throws -> Int {
    var multiplier = 1
    var value = 0
    var encodedByte: UInt8 = 0
    repeat {
        guard data.hasSize(1) else {
            throw DecodeError.malformedData
        }
        encodedByte = data.read1ByteInt()
        value += (Int(encodedByte) & 127) * multiplier
        multiplier *= 128
        if multiplier > 128 * 128 * 128 {
            break
        }
    } while (encodedByte & 128) != 0
    return value
}
