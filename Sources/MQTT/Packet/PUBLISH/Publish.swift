import Foundation

public final class PublishPacket: MQTTPacket {
    public let variableHeader: VariableHeader
    public let payload: Data

    public var qos: QoS {
        QoS(rawValue: fixedHeader.flags >> 1 & 0b11)!
    }

    init(topic: String, identifier: UInt16, retain: Bool, qos: QoS, payload: Data) {
        var flags: UInt8 = 0
        flags |= qos.rawValue << 1
        flags |= retain ? 1 : 0
        variableHeader = VariableHeader(topic: topic, identifier: qos == QOS.0 ? nil : identifier)
        self.payload = payload
        super.init(fixedHeader: FixedHeader(packetType: .publish, flags: flags))
    }

    init(fixedHeader: FixedHeader, data: Data) throws {
        let qos = try QoS(value: (fixedHeader.flags >> 1) & 0b11)
        if data.count < 2 {
            throw DecodeError.malformedData
        }
        let topicLen = UInt16(data[0]) << 8 | UInt16(data[1])
        var remainData = data.advanced(by: 2)
        if remainData.count < topicLen {
            throw DecodeError.malformedData
        }
        let topic = String(data: remainData[..<topicLen], encoding: .utf8) ?? ""
        let identifier: UInt16?
        if remainData.count > topicLen {
            remainData = remainData.advanced(by: Int(topicLen))
            if qos == .atMostOnce {
                identifier = nil
            } else {
                if remainData.count < 2 {
                    throw DecodeError.malformedData
                }
                identifier = UInt16(remainData[0]) << 8 | UInt16(remainData[1])
                remainData = remainData.advanced(by: 2)
            }
        } else {
            remainData = Data()
            identifier = nil
        }
        variableHeader = VariableHeader(topic: topic, identifier: identifier)
        payload = remainData
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
