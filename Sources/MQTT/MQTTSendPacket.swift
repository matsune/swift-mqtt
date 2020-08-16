import Foundation

public protocol MQTTSendPacket: MQTTPacket {
    associatedtype VariableHeader: DataEncodable = DataUnused
    associatedtype Payload: DataEncodable = DataUnused
}

extension MQTTSendPacket where VariableHeader: DataEncodable, Payload: DataEncodable {
    public var encodedData: Data {
        var body = Data()
        if let variableHeader = variableHeader {
            body.append(variableHeader.encodedData)
        }
        if let payload = payload {
            body.append(payload.encodedData)
        }
        var data = Data()
        data.append(fixedHeader.byte1)
        data.append(encode(remainingLength: body.count))
        data.append(body)
        return data
    }
}
