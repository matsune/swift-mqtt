import Foundation

/// # Reference
/// [PUBLISH – Publish message](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718037)
public final class PublishPacket: MQTTPacket {
    public let variableHeader: VariableHeader
    public let payload: DataEncodable

    public var qos: QoS {
        QoS(rawValue: fixedHeader.flags >> 1 & 0b11)!
    }

    public var topic: String {
        variableHeader.topic
    }

    public var identifier: UInt16? {
        variableHeader.identifier
    }

    init(topic: String, identifier: UInt16?, retain: Bool, qos: QoS, payload: DataEncodable) {
        var flags: UInt8 = 0
        flags |= qos.rawValue << 1
        flags |= retain ? 1 : 0
        if qos == .atMostOnce {
            // QoS = 0
            if identifier != nil {
                fatalError("A PUBLISH Packet MUST NOT contain a Packet Identifier if its QoS value is set to 0")
            }
        } else {
            // QoS > 0
            guard let identifier = identifier, identifier > 0 else {
                fatalError("A PUBLISH Packet with QoS > 0 Control Packets MUST contain a non-zero 16-bit Packet Identifier ")
            }
        }
        variableHeader = VariableHeader(topic: topic, identifier: identifier)
        self.payload = payload
        super.init(fixedHeader: FixedHeader(packetType: .publish, flags: flags))
    }

    init(fixedHeader: FixedHeader, data: inout Data) throws {
        let qos = try QoS(value: (fixedHeader.flags >> 1) & 0b11)
        guard data.hasSize(2) else {
            throw DecodeError.malformedData
        }
        let topicLen = data.read2BytesInt()
        guard data.hasSize(topicLen) else {
            throw DecodeError.malformedData
        }
        let topic = String(data: data.read(bytes: topicLen), encoding: .utf8) ?? ""

        let identifier: UInt16?
        if qos == .atMostOnce {
            identifier = nil
        } else {
            guard data.hasSize(2) else {
                throw DecodeError.malformedData
            }
            identifier = data.read2BytesInt()
        }
        variableHeader = VariableHeader(topic: topic, identifier: identifier)
        payload = data
        super.init(fixedHeader: fixedHeader)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}

extension PublishPacket {
    public struct VariableHeader: DataEncodable {
        public let topic: String
        public let identifier: UInt16?

        public func encode() -> Data {
            var data = Data()
            data.write(topic)
            if let identifier = identifier {
                data.write(identifier)
            }
            return data
        }
    }
}
