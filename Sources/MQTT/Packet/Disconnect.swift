class DisconnectPacket: MQTTSendPacket {
    let fixedHeader: FixedHeader
    
    init() {
        self.fixedHeader = FixedHeader(packetType: .disconnect, flags: 0)
    }
}
