public struct FixedHeader {
    let packetType: MQTTPacketType
    let flags: UInt8

    var byte1: UInt8 {
        (packetType.rawValue << 4) | (flags & 0b0000_1111)
    }
}
