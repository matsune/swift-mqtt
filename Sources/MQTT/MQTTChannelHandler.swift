import Foundation
import NIO

protocol MQTTChannelHandlerDelegate: AnyObject {
    func didReceive(packet: MQTTPacket)
    func didCatch(decodeError error: DecodeError)
}

final class MQTTChannelHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    var clientID: String
    var cleanSession: Bool
    var keepAlive: UInt16

    let decoder = MQTTDecoder()
    weak var delegate: MQTTChannelHandlerDelegate?

    init(
        clientID: String,
        cleanSession: Bool,
        keepAlive: UInt16
    ) {
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
    }

    func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        if let bytes = buf.readBytes(length: buf.readableBytes) {
            var data = Data(bytes)
            do {
                let packet = try decoder.decode(data: &data)
                delegate?.didReceive(packet: packet)
            } catch let error as DecodeError {
                delegate?.didCatch(decodeError: error)
            } catch {
                // unhandled error
                fatalError("Error while decoding packet data: \(error.localizedDescription)")
            }
        }
    }
}
