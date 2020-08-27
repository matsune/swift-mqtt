import Foundation

/// # Reference
/// [PUBREL – Publish release (QoS 2 publish received, part 2)](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718053)
final class PubRelPacket: MQTTPacket {
    let variableHeader: VariableHeader
    
    var identifier: UInt16 {
        variableHeader.identifier
    }

    init(identifier: UInt16) {
        self.variableHeader = VariableHeader(identifier: identifier)
        super.init(packetType: .pubrel, flags: 0b0010)
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
