import Foundation

public final class ConnAck: MQTTRecvPacket {
    public enum ReturnCode: UInt8 {
        case accepted = 0
        case unaceptable = 1
        case identifierRejected = 2
        case serverUnavailable = 3
        case badUserCredential = 4
        case notAuthorized = 5
    }

    struct VariableHeader: DataDecodable {
        let sessionPresent: Bool
        let returnCode: ReturnCode

        init(data: Data) throws {
            sessionPresent = (data[0] & 1) == 1
            returnCode = ReturnCode(rawValue: data[1])!
        }
    }

    let variableHeader: VariableHeader

    public var returnCode: ReturnCode {
        variableHeader.returnCode
    }

    public var sessionPresent: Bool {
        variableHeader.sessionPresent
    }

    required init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        super.init(fixedHeader: fixedHeader)
    }
}
