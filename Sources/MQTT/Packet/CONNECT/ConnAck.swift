import Foundation

/// # Reference
/// [CONNACK – Acknowledge connection request](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718033)
public final class ConnAckPacket: MQTTPacket {
    private let variableHeader: VariableHeader

    public var returnCode: ReturnCode {
        variableHeader.returnCode
    }

    public var sessionPresent: Bool {
        variableHeader.sessionPresent
    }

    init(fixedHeader: FixedHeader, data: inout Data) throws {
        guard data.hasSize(2) else {
            throw DecodeError.malformedData
        }
        let sessionPresent = (data.read1ByteInt() & 1) == 1
        let returnCode = try ReturnCode(code: data.read1ByteInt())
        variableHeader = VariableHeader(sessionPresent: sessionPresent, returnCode: returnCode)
        super.init(fixedHeader: fixedHeader)
    }
}

extension ConnAckPacket {
    struct VariableHeader {
        let sessionPresent: Bool
        let returnCode: ReturnCode
    }

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
}
