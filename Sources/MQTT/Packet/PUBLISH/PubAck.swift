import Foundation

/// A PUBACK Packet is the response to a PUBLISH Packet with QoS level 1.
public final class PubAckPacket: MQTTPacket {
    private let variableHeader: VariableHeader

    public var identifier: UInt16 {
        variableHeader.identifier
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        if data.count < 2 {
            throw DecodeError.malformedData
        }
        let identifier = UInt16(data[0]) << 8 | UInt16(data[1])
        variableHeader = VariableHeader(identifier: identifier)
        super.init(fixedHeader: fixedHeader)
    }

    init(identifier: UInt16) {
        variableHeader = VariableHeader(identifier: identifier)
        super.init(fixedHeader: FixedHeader(packetType: .puback, flags: 0))
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: nil)
    }
}

extension PubAckPacket {
    struct VariableHeader: DataEncodable {
        let identifier: UInt16

        init(identifier: UInt16) {
            self.identifier = identifier
        }

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }
}
