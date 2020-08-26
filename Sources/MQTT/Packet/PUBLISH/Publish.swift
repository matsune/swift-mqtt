import Foundation

public class Publish: MQTTRecvPacket, MQTTSendPacket {
    public let variableHeader: VariableHeader
    public let payload: Data

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

    public var qos: QoS {
        QoS(rawValue: fixedHeader.flags >> 1 & 0b11)!
    }

    init(topic: String, identifier: UInt16, retain: Bool, qos: QoS, payload: Data) {
        var flags: UInt8 = 0
        flags |= qos.rawValue << 1
        flags |= retain ? 0b0000_0001 : 0
        variableHeader = VariableHeader(topic: topic, identifier: qos == QOS.0 ? nil : identifier)
        self.payload = payload
        super.init(fixedHeader: FixedHeader(packetType: .publish, flags: flags))
    }

    init(fixedHeader: FixedHeader, data: Data) {
        let qos = QoS(rawValue: (fixedHeader.flags >> 1) & 0b11)!
        let topicLen = UInt16(data[0]) << 8 | UInt16(data[1])
        let topic = String(data: data.advanced(by: 2)[..<topicLen], encoding: .utf8) ?? ""
        let identifier: UInt16?
        var remainData: Data
        if data.count > Int(topicLen) + 2 {
            remainData = data.advanced(by: 2 + Int(topicLen))
        } else {
            remainData = Data()
        }
        if qos == QOS.0 {
            identifier = nil
        } else {
            identifier = UInt16(remainData[0]) << 8 | UInt16(remainData[1])
            remainData = remainData.advanced(by: 2)
        }
        variableHeader = VariableHeader(topic: topic, identifier: identifier)
        payload = remainData
        super.init(fixedHeader: fixedHeader)
    }

    func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}
