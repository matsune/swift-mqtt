import Foundation

public protocol MQTTPacket {
    associatedtype VariableHeader
    associatedtype Payload
 
    var packetType: PacketType { get }
    var fixedHeader: FixedHeader { get }
    var variableHeader: VariableHeader? { get }
    var payload: Payload? { get }
}

extension MQTTPacket {
    public var packetType: PacketType {
        fixedHeader.packetType
    }
}

public protocol DataEncodable {
    var encodedData: Data { get }
}

public protocol DataDecodable {
    init(data: Data) throws
}

public final class DataUnused: DataEncodable, DataDecodable {
    public var encodedData: Data {
        fatalError("never used")
    }
    
    public required init(data: Data) throws {
        fatalError()
    }
}

public extension MQTTPacket where VariableHeader: DataUnused {
    var variableHeader: VariableHeader? {
        return nil
    }
}

public extension MQTTPacket where Payload: DataUnused {
    var payload: Payload? {
        return nil
    }
}
