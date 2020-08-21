import Foundation

/// A PUBREC Packet is the response to a PUBLISH Packet with QoS 2. It is the second packet of the QoS 2 protocol exchange.
public class PubRec: MQTTRecvPacket {
    struct VariableHeader: DataDecodable {
        let identifier: UInt16

        init(data: Data) throws {
            guard data.count == 2 else {
                throw DecodeError.malformedData
            }
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
        }
    }

    let variableHeader: VariableHeader

    public var identifier: UInt16 {
        variableHeader.identifier
    }

    required init(data: Data) throws {
        let remainLen = try decodeRemainLen(data: data)
        variableHeader = try VariableHeader(data: data.advanced(by: remainLen))
        super.init(packetType: .pubrec, flags: 0)
    }
}
