import Foundation

class PingrespPacket: MQTTRecvPacket {
    override init(data: Data) throws {
        super.init(packetType: .pingresp, flags: 0)
    }
}
