/// # Reference
/// [DISCONNECT – Disconnect notification](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718090)
final class DisconnectPacket: MQTTPacket {
    init() {
        super.init(packetType: .disconnect, flags: 0)
    }
}
