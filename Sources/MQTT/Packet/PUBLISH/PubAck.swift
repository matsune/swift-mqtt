import Foundation

/// # Reference
/// [PUBACK – Publish acknowledgement](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718043)
public final class PubAckPacket: MQTTPacket {
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

extension PubAckPacket {
    struct VariableHeader {
        let identifier: UInt16
    }
}
