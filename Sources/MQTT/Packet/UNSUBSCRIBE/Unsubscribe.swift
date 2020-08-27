import Foundation

/// # Reference
/// [UNSUBSCRIBE – Unsubscribe from topics](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718072)
class UnsubscribePacket: MQTTPacket {
    let variableHeader: VariableHeader
    let payload: Payload
    
    var identifier: UInt16 {
        variableHeader.identifier
    }
    
    var topicFilters: [String] {
        payload.topicFilters
    }

    init(identifier: UInt16, topicFilters: [String]) {
        variableHeader = VariableHeader(identifier: identifier)
        payload = Payload(topicFilters: topicFilters)
        super.init(packetType: .unsubscribe, flags: 0b0010)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}

extension UnsubscribePacket {
    struct VariableHeader: DataEncodable {
        let identifier: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }

    struct Payload: DataEncodable {
        let topicFilters: [String]

        func encode() -> Data {
            var data = Data()
            topicFilters.forEach { data.write($0) }
            return data
        }
    }
}
