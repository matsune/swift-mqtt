import Foundation

public final class ConnAckPacket: MQTTPacket {
    public enum ReturnCode: UInt8 {
        case accepted = 0
        case unaceptable = 1
        case identifierRejected = 2
        case serverUnavailable = 3
        case badUserCredential = 4
        case notAuthorized = 5

        init(code: UInt8) throws {
            guard let returnCode = ReturnCode(rawValue: code) else {
                throw DecodeError.malformedConnAckReturnCode
            }
            self = returnCode
        }
    }

    private let variableHeader: VariableHeader

    public var returnCode: ReturnCode {
        variableHeader.returnCode
    }

    public var sessionPresent: Bool {
        variableHeader.sessionPresent
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        variableHeader = try VariableHeader(data: data)
        super.init(fixedHeader: fixedHeader)
    }
}

extension ConnAckPacket {
    struct VariableHeader {
        let sessionPresent: Bool
        let returnCode: ReturnCode

        init(data: Data) throws {
            if data.isEmpty {
                throw DecodeError.malformedData
            }
            sessionPresent = (data[0] & 1) == 1
            returnCode = try ReturnCode(code: data[1])
        }
    }
}
