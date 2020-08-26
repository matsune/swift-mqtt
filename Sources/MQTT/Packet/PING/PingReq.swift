class PingReq: MQTTPacket, MQTTSendPacket {
    init() {
        super.init(packetType: .pingreq, flags: 0)
    }
}
