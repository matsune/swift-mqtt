import MQTT
import Foundation
import NIO

func log(_ items: Any...) {
    print("\(Date())", items)
}

class Handler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    func channelActive(context: ChannelHandlerContext) {
        log("active")
        let data = ConnectPacket(clientID: "swift-mqtt-client", keepAliveSec: 30).encodedData
        context.writeAndFlush(wrapOutboundOut(ByteBuffer(bytes: [UInt8](data))))
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        if let bytes = buf.readBytes(length: buf.readableBytes) {
            let data = Data(bytes)
            
            do {
                if #available(OSX 10.15.0, *) {
                    let packet = try decode(data: data)
                    log(">>> \(packet)")
                } else {
                    // Fallback on earlier versions
                }
            } catch {
                print("error \(error)")
            }
        }
    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let bootstrap = ClientBootstrap(group: group)
    .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .channelInitializer { channel in
        channel.pipeline.addHandler(Handler())
    }
defer {
    try! group.syncShutdownGracefully()
}
do {
    let channel = try bootstrap.connect(host: "localhost", port: 8883).wait()
    log("close future wait")
    try channel.closeFuture.wait()
} catch {
    print("Error \(error)")
}

log("end")
