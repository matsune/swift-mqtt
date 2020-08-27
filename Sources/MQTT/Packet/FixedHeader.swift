/// # Reference
/// [Fixed header](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718020)
public struct FixedHeader {
    let packetType: MQTTPacketType
    let flags: UInt8

    var byte1: UInt8 {
        (packetType.rawValue << 4) | (flags & 0b0000_1111)
    }
}
