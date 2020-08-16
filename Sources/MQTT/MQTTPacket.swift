import Foundation

public protocol MQTTPacket {
    associatedtype VariableHeader
    associatedtype Payload
    
    var fixedHeader: FixedHeader { get }
    var variableHeader: VariableHeader? { get }
    var payload: Payload? { get }
}

public protocol DataEncodable {
    var encodedData: Data { get }
}

public protocol DataDecodable {
    init(data: Data) throws
}

public class DataUnused: DataEncodable, DataDecodable {
    public var encodedData: Data {
        fatalError("never used")
    }
    
    public required init(data: Data) throws {
        fatalError()
    }
}

extension MQTTPacket where VariableHeader: DataUnused {
    public var variableHeader: VariableHeader? {
        return nil
    }
}

extension MQTTPacket where Payload: DataUnused {
    public var payload: Payload? {
        return nil
    }
}
