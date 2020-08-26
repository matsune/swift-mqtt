import Foundation

class UnsubscribePacket: MQTTPacket {
    let identifier: UInt16
    let topicFilters: [String]

    init(identifier: UInt16, topicFilters: [String]) {
        self.identifier = identifier
        self.topicFilters = topicFilters
        super.init(packetType: .unsubscribe, flags: 0b0010)
    }

    override func encode() -> Data {
        encode(variableHeader: VariableHeader(identifier: identifier),
               payload: Payload(filters: topicFilters))
    }
}

extension UnsubscribePacket {
    struct TopicFilter: DataEncodable {
        let topic: String
        let qos: QoS

        func encode() -> Data {
            var data = Data()
            data.write(topic)
            data.write(qos.rawValue)
            return data
        }
    }

    struct VariableHeader: DataEncodable {
        let identifier: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }

    struct Payload: DataEncodable {
        let filters: [String]

        func encode() -> Data {
            var data = Data()
            filters.forEach { data.write($0) }
            return data
        }
    }
}
