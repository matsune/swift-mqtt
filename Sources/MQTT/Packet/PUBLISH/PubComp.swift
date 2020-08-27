import Foundation

/// # Reference
/// [PUBCOMP – Publish complete (QoS 2 publish received, part 3)](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718058)
public final class PubCompPacket: MQTTPacket {
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

extension PubCompPacket {
    struct VariableHeader {
        let identifier: UInt16
    }
}
