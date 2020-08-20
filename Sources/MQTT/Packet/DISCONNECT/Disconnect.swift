class DisconnectPacket: MQTTSendPacket {
    init() {
        super.init(packetType: .disconnect, flags: 0)
    }
}
