import Foundation

public class PingResp: MQTTRecvPacket {
    override init(fixedHeader: FixedHeader) {
        super.init(fixedHeader: fixedHeader)
    }
}
