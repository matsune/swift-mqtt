import Foundation

/// A PUBREL Packet is the response to a PUBREC Packet. It is the third packet of the QoS 2 protocol exchange.
final class PubRelPacket: MQTTPacket {
    let identifier: UInt16

    init(identifier: UInt16) {
        self.identifier = identifier
        super.init(packetType: .pubrel, flags: 0b0010)
    }

    var variableHeader: VariableHeader {
        VariableHeader(identifier: identifier)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: nil)
    }
}

extension PubRelPacket {
    struct VariableHeader: DataEncodable {
        let identifier: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(identifier)
            return data
        }
    }
}
