class Disconnect: MQTTSendPacket {
    init() {
        super.init(packetType: .disconnect, flags: 0)
    }
}
