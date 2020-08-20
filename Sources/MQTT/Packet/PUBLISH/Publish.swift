import Foundation

struct PublishVariableHeader: DataEncodable {
    let topicName: String
    let identifier: UInt16
    
    func encode() -> Data {
        var data = Data()
        data.write(topicName)
        data.write(identifier)
        return data
    }
}

class Publish<Payload: DataEncodable>: MQTTSendPacket {
    let topicName: String
    let identifier: UInt16
    let payload: Payload
    
    init(dup: Bool, qos: QoS, retain: Bool, topicName: String, identifier: UInt16, payload: Payload) {
        var flags: UInt8 = 0
        if dup && qos != QOS.0 { // DUP flag MUST be set to 0 for all QoS 0 messages
            flags |= 0b1000
        }
        flags |= qos.rawValue << 1
        flags |= retain ? 0b0000_0001 : 0
        self.topicName = topicName
        self.identifier = identifier
        self.payload = payload
        super.init(packetType: .publish, flags: flags)
    }
    
    var qos: QoS {
        let flags = (self.fixedHeader.flags >> 1) & 0b0011
        return QoS(rawValue: flags) ?? QOS.0
    }
    
    var variableHeader: PublishVariableHeader {
        PublishVariableHeader(topicName: self.topicName, identifier: qos.rawValue > 0 ? identifier : 0)
    }
    
    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}

