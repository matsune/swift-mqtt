class Disconnect: MQTTPacket, MQTTSendPacket {
    init() {
        super.init(packetType: .disconnect, flags: 0)
    }
}
