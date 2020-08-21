import Foundation

class Publish<Payload: DataEncodable>: MQTTSendPacket {
    let topic: String
    let identifier: UInt16
//    let retain: Bool
//    let qos: QoS
    let payload: Payload

    struct VariableHeader: DataEncodable {
        let topic: String
        let identifier: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(topic)
            data.write(identifier)
            return data
        }
    }

    init(topic: String, identifier: UInt16, retain: Bool, qos: QoS, payload: Payload) {
        self.topic = topic
        self.identifier = identifier
        self.payload = payload
        var flags: UInt8 = 0
        // DUP flag MUST be set to 0 for all QoS 0 messages
        flags |= qos == QOS.0 ? 0 : 0b1000
        flags |= qos.rawValue << 1
        flags |= retain ? 0b0000_0001 : 0
        super.init(packetType: .publish, flags: flags)
    }

    var variableHeader: VariableHeader {
        VariableHeader(topic: topic, identifier: identifier)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}
