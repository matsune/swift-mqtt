import Foundation

/// The PUBCOMP Packet is the response to a PUBREL Packet. It is the fourth and final packet of the QoS 2 protocol exchange.
public class PubComp: MQTTRecvPacket {
    struct VariableHeader: DataDecodable {
        let identifier: UInt16

        init(data: Data) throws {
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
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
}
