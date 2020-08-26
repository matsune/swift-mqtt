import Foundation

class UnsubAck: MQTTRecvPacket {
    struct VariableHeader: DataDecodable {
        let identifier: UInt16

        init(data: Data) throws {
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
        }
    }

    let variableHeader: VariableHeader

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        super.init(fixedHeader: fixedHeader)
    }
}
