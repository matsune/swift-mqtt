class PingreqPacket: MQTTSendPacket {
    init() {
        super.init(packetType: .pingreq, flags: 0)
    }
}
