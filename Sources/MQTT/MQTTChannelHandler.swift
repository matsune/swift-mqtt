import Foundation
import NIO

protocol MQTTChannelHandlerDelegate: AnyObject {
    func didReceive(packet: MQTTPacket)
    func didCatch(decodeError error: DecodeError)
    func channelActive(channel: Channel)
    func channelInactive()
}

final class MQTTChannelHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let decoder: MQTTDecoder
    weak var delegate: MQTTChannelHandlerDelegate?

    init(decoder: MQTTDecoder = MQTTDecoder()) {
        self.decoder = decoder
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

    func channelActive(context: ChannelHandlerContext) {
        delegate?.channelActive(channel: context.channel)
    }

    func channelInactive(context _: ChannelHandlerContext) {
        delegate?.channelInactive()
    }
}
