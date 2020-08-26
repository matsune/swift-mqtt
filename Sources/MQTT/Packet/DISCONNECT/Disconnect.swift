final class DisconnectPacket: MQTTPacket {
    init() {
        super.init(packetType: .disconnect, flags: 0)
    }
}
