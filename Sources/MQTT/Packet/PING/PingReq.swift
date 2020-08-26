final class PingReqPacket: MQTTPacket {
    init() {
        super.init(packetType: .pingreq, flags: 0)
    }
}
