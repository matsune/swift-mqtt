class PingReq: MQTTSendPacket {
    init() {
        super.init(packetType: .pingreq, flags: 0)
    }
}
