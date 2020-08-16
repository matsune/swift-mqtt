import Foundation

public struct ConnackVariableHeader: DataDecodable {
    enum ReturnCode: UInt8 {
        case accepted = 0
        case unaceptable = 1
        case identifierRejected = 2
        case serverUnavailable = 3
        case badUserCredential = 4
        case notAuthorized = 5
        case unknown
    }
    
    let sessionPresent: Bool
    let returnCode: ReturnCode
    
    public init(data: Data) throws {
        sessionPresent = (data[0] & 0b0000_0001) == 1
        returnCode = ReturnCode(rawValue: data[1]) ?? .unknown
    }
}

public class ConnackPacket: MQTTRecvPacket {
    public typealias VariableHeader = ConnackVariableHeader
    
    public let fixedHeader: FixedHeader
    public let variableHeader: ConnackVariableHeader?
    
    public init(data: Data) throws {
        self.fixedHeader = FixedHeader(packetType: .connack, flags: 0)
        let remainLen = try decode(remainingLength: data)
        self.variableHeader = try ConnackVariableHeader(data: data.advanced(by: data.count - remainLen))
    }
}
