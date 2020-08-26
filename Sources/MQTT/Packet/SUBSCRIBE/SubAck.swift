import Foundation

class SubAck: MQTTRecvPacket {
    enum ReturnCode {
        case success(QoS)
        case failure
    }

    struct VariableHeader: DataDecodable {
        let identifier: UInt16

        init(data: Data) throws {
            identifier = UInt16(data[0] << 8) | UInt16(data[1])
        }
    }

    let variableHeader: VariableHeader
    let returnCodes: [ReturnCode]

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        let payloadData = data.advanced(by: 2)
        returnCodes = try payloadData.map {
            switch $0 {
            case 0x00:
                return ReturnCode.success(QOS.0)
            case 0x01:
                return ReturnCode.success(QOS.1)
            case 0x02:
                return ReturnCode.success(QOS.2)
            case 0x80:
                return ReturnCode.failure
            default:
                throw DecodeError.malformedData
            }
        }
        super.init(fixedHeader: fixedHeader)
    }
}
