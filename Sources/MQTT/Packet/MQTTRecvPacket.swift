public protocol MQTTRecvPacket: MQTTPacket {
    associatedtype VariableHeader: DataDecodable = DataUnused
    associatedtype Payload: DataDecodable = DataUnused
}
