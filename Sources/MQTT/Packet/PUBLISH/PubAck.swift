import Foundation

/// A PUBACK Packet is the response to a PUBLISH Packet with QoS level 1.
public class PubAck: MQTTRecvPacket, MQTTSendPacket {
    struct VariableHeader: DataEncodable, DataDecodable {
        let identifier: UInt16

        init(data: Data) throws {
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
        }

        init(identifier: UInt16) {
            self.identifier = identifier
        }

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }

    let variableHeader: VariableHeader

    public var identifier: UInt16 {
        variableHeader.identifier
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        super.init(fixedHeader: fixedHeader)
    }

    init(identifier: UInt16) {
        variableHeader = VariableHeader(identifier: identifier)
        super.init(fixedHeader: FixedHeader(packetType: .puback, flags: 0))
    }

    func encode() -> Data {
        encode(variableHeader: variableHeader, payload: nil)
    }
}
