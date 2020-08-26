import Foundation

public class MQTTPacket {
    let fixedHeader: FixedHeader

    init(packetType: PacketType, flags: UInt8) {
        fixedHeader = FixedHeader(packetType: packetType, flags: flags)
    }

    init(fixedHeader: FixedHeader) {
        self.fixedHeader = fixedHeader
    }
}

public struct FixedHeader: DataDecodable {
    let packetType: PacketType
    let flags: UInt8

    var byte1: UInt8 {
        (packetType.rawValue << 4) | (flags & 0b0000_1111)
    }

    public init(data: Data) throws {
        packetType = PacketType(rawValue: data[0] >> 4)!
        flags = data[0] & 0x0F
    }

    init(packetType: PacketType, flags: UInt8) {
        self.packetType = packetType
        self.flags = flags
    }
}

protocol MQTTSendPacket {
    func encode() -> Data
}

extension MQTTSendPacket where Self: MQTTPacket {
    func encode(variableHeader: DataEncodable?, payload: DataEncodable?) -> Data {
        var body = Data()
        if let variableHeader = variableHeader {
            body.append(variableHeader.encode())
        }
        if let payload = payload {
            body.append(payload.encode())
        }
        var data = Data()
        data.append(fixedHeader.byte1)
        data.append(encodeRemainLen(body.count))
        data.append(body)
        return data
    }

    func encode() -> Data {
        encode(variableHeader: nil, payload: nil)
    }
}

public class MQTTRecvPacket: MQTTPacket {
    override init(fixedHeader: FixedHeader) {
        super.init(fixedHeader: fixedHeader)
    }

//    override init(packetType: PacketType, flags: UInt8) {
//        super.init(packetType: packetType, flags: flags)
//    }
}
