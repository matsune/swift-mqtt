import Foundation

final class UnsubAckPacket: MQTTPacket {
    private let variableHeader: VariableHeader

    var identifier: UInt16 {
        variableHeader.identifier
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        super.init(fixedHeader: fixedHeader)
    }
}

extension UnsubAckPacket {
    struct VariableHeader {
        let identifier: UInt16

        init(data: Data) throws {
            if data.count < 2 {
                throw DecodeError.malformedData
            }
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
        }
    }
}
