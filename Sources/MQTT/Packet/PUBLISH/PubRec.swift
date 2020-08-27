import Foundation

/// # Reference
/// [PUBREC – Publish received (QoS 2 publish received, part 1)](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718048)
public final class PubRecPacket: MQTTPacket {
    private let variableHeader: VariableHeader

    public var identifier: UInt16 {
        variableHeader.identifier
    }

    init(fixedHeader: FixedHeader, data: inout Data) throws {
        guard data.hasSize(2) else {
            throw DecodeError.malformedData
        }
        variableHeader = VariableHeader(identifier: data.read2BytesInt())
        super.init(fixedHeader: fixedHeader)
    }
}

extension PubRecPacket {
    struct VariableHeader {
        let identifier: UInt16
    }
}
