/// # Reference
/// [PINGREQ – PING request](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718081)
final class PingReqPacket: MQTTPacket {
    init() {
        super.init(packetType: .pingreq, flags: 0)
    }
}
