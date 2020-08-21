import Foundation

public class PingResp: MQTTRecvPacket {
    required init(data _: Data) throws {
        super.init(packetType: .pingresp, flags: 0)
    }
}
