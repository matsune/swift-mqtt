import Foundation

/// A PUBACK Packet is the response to a PUBLISH Packet with QoS level 1.
public class PubAck: MQTTRecvPacket {
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
        super.init(packetType: .puback, flags: 0)
    }
}
