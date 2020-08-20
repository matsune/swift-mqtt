import Foundation

public struct ConnackVariableHeader: DataDecodable {
    public enum ReturnCode: UInt8 {
        case accepted = 0
        case unaceptable = 1
        case identifierRejected = 2
        case serverUnavailable = 3
        case badUserCredential = 4
        case notAuthorized = 5
        case unknown
    }
    
    public let sessionPresent: Bool
    public let returnCode: ReturnCode
    
    public init(data: Data) throws {
        sessionPresent = (data[0] & 0b0000_0001) == 1
        returnCode = ReturnCode(rawValue: data[1]) ?? .unknown
    }
}

public final class ConnackPacket: MQTTRecvPacket {
    public typealias VariableHeader = ConnackVariableHeader
    
    public let variableHeader: ConnackVariableHeader
    
    public var returnCode: ConnackVariableHeader.ReturnCode {
        variableHeader.returnCode
    }

    public var sessionPresent: Bool {
        variableHeader.sessionPresent
    }
    
    override init(data: Data) throws {
        let remainLen = try decodeRemainLen(data: data)
        self.variableHeader = try ConnackVariableHeader(data: data.advanced(by: data.count - remainLen))
        super.init(packetType: .connack, flags: 0)
    }
}
