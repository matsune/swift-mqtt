import Foundation

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

class SubscribePacket: MQTTPacket {
    let identifier: UInt16
    let topicFilters: [TopicFilter]

    init(identifier: UInt16, topicFilters: [TopicFilter]) {
        self.identifier = identifier
        self.topicFilters = topicFilters
        super.init(packetType: .subscribe, flags: 0b0010)
    }

    override func encode() -> Data {
        encode(variableHeader: VariableHeader(identifier: identifier),
               payload: Payload(filters: topicFilters))
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
        let filters: [TopicFilter]

        func encode() -> Data {
            var data = Data()
            filters.forEach { data.append($0.encode()) }
            return data
        }
    }
}
