import Foundation

/// # Reference
/// [SUBSCRIBE - Subscribe to topics](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718063)
final class SubscribePacket: MQTTPacket {
    let variableHeader: VariableHeader
    let payload: Payload

    var identifier: UInt16 {
        variableHeader.identifier
    }

    var topicFilters: [TopicFilter] {
        payload.topicFilters
    }

    init(identifier: UInt16, topicFilters: [TopicFilter]) {
        variableHeader = VariableHeader(identifier: identifier)
        payload = Payload(topicFilters: topicFilters)
        super.init(packetType: .subscribe, flags: 0b0010)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}

extension SubscribePacket {
    struct VariableHeader: DataEncodable {
        let identifier: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }

    struct Payload: DataEncodable {
        let topicFilters: [TopicFilter]

        func encode() -> Data {
            var data = Data()
            topicFilters.forEach { data.append($0.encode()) }
            return data
        }
    }
}

public struct TopicFilter {
    let topic: String
    let qos: QoS

    func encode() -> Data {
        var data = Data()
        data.write(topic)
        data.write(qos.rawValue)
        return data
    }
}
