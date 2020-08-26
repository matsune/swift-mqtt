import Foundation

final class SubAckPacket: MQTTPacket {
    private let variableHeader: VariableHeader
    let returnCodes: [ReturnCode]

    var identifier: UInt16 {
        variableHeader.identifier
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        let payloadData = data.advanced(by: 2)
        returnCodes = try payloadData.map { try ReturnCode(code: $0) }
        super.init(fixedHeader: fixedHeader)
    }
}

extension SubAckPacket {
    enum ReturnCode {
        case success(QoS)
        case failure

        init(code: UInt8) throws {
            switch code {
            case 0x00, 0x01, 0x02:
                self = .success(try QoS(value: code))
            case 0x80:
                self = .failure
            default:
                throw DecodeError.malformedSubAckReturnCode
            }
        }
    }

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
