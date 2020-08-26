public enum MQTTPacketType: UInt8 {
    /// Client request to connect to Server
    case connect = 0x01
    /// Connect acknowledgment
    case connack = 0x02
    /// Publish message
    case publish = 0x03
    /// Publish acknowledgment
    case puback = 0x04
    /// Publish received (assured delivery part 1)
    case pubrec = 0x05
    /// Publish release (assured delivery part 2)
    case pubrel = 0x06
    /// Publish complete (assured delivery part 3)
    case pubcomp = 0x07
    /// Client subscribe request
    case subscribe = 0x08
    /// Subscribe acknowledgment
    case suback = 0x09
    /// Unsubscribe request
    case unsubscribe = 0x0A
    /// Unsubscribe acknowledgment
    case unsuback = 0x0B
    /// PING request
    case pingreq = 0x0C
    /// PING response
    case pingresp = 0x0D
    /// Client is disconnecting
    case disconnect = 0x0E

    init(packet: UInt8) throws {
        guard let type = MQTTPacketType(rawValue: packet) else {
            throw DecodeError.malformedPacketType
        }
        self = type
    }
}
