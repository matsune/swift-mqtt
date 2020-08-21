import Foundation

public final class ConnAck: MQTTRecvPacket {
    public enum ReturnCode: UInt8 {
        case accepted = 0
        case unaceptable = 1
        case identifierRejected = 2
        case serverUnavailable = 3
        case badUserCredential = 4
        case notAuthorized = 5
        case unknown
    }

    struct VariableHeader: DataDecodable {
        let sessionPresent: Bool
        let returnCode: ReturnCode

        init(data: Data) throws {
            sessionPresent = (data[0] & 0b0000_0001) == 1
            returnCode = ReturnCode(rawValue: data[1]) ?? .unknown
        }
    }

    let variableHeader: VariableHeader

    public var returnCode: ReturnCode {
        variableHeader.returnCode
    }

    public var sessionPresent: Bool {
        variableHeader.sessionPresent
    }

    required init(data: Data) throws {
        let remainLen = try decodeRemainLen(data: data)
        variableHeader = try VariableHeader(data: data.advanced(by: data.count - remainLen))
        super.init(packetType: .connack, flags: 0)
    }
}
