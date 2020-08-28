import Foundation

/// MQTT Control Packet
///
/// # Reference
/// [MQTT Control Packet format](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718018)
public class MQTTPacket {
    let fixedHeader: FixedHeader

    init(packetType: MQTTPacketType, flags: UInt8) {
        fixedHeader = FixedHeader(packetType: packetType, flags: flags)
    }

    init(fixedHeader: FixedHeader) {
        self.fixedHeader = fixedHeader
    }

    func encode() -> Data {
        encode(variableHeader: nil, payload: nil)
    }

    func encode(variableHeader: DataEncodable?, payload: DataEncodable?) -> Data {
        var body = Data()
        if let variableHeader = variableHeader {
            body.append(variableHeader.encode())
        }
        if let payload = payload {
            body.append(payload.encode())
        }
        var data = Data()
        data.append(fixedHeader.byte1)
        data.append(encodeRemainLen(body.count))
        data.append(body)
        return data
    }
}

internal func encodeRemainLen(_ length: Int) -> Data {
    var data = Data(capacity: 4)
    var x = length
    var encodedByte: UInt8 = 0
    repeat {
        encodedByte = UInt8(x % 128)
        x /= 128
        if x > 0 {
            encodedByte |= 128
        }
        data.append(encodedByte)
    } while x > 0
    return data
}
