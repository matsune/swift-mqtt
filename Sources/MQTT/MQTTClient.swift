import Foundation
import NIO

protocol HandlerDelegate: AnyObject {
    func didReceive<Packet: MQTTRecvPacket>(packet: Packet)
}

class Handler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    var clientID: String
    var cleanSession: Bool
    var keepAlive: UInt16
    
    weak var delegate: HandlerDelegate?
    
    init(
        clientID: String,
        cleanSession: Bool,
        keepAlive: UInt16
    ) {
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        if let bytes = buf.readBytes(length: buf.readableBytes) {
            let data = Data(bytes)
            do {
                let packet = try decode(data: data)
                delegate?.didReceive(packet: packet)
            } catch {
                print("error \(error)")
            }
        }
    }
}

public protocol MQTTClientDelegate: AnyObject {
    func didReceive<Packet: MQTTRecvPacket>(packet: Packet)
}

public class MQTTClient {
    public enum Domain {
        case ip(host: String, port: Int)
        case unix(path: String)
    }
    
    public var domain: Domain
    public var clientID: String
    public var cleanSession: Bool
    public var keepAlive: UInt16

    public weak var delegate: MQTTClientDelegate?
    
    private let group: EventLoopGroup
    private var channel: Channel?
    
    
    
    public init(
        domain: Domain,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16
    ) {
        self.domain = domain
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    deinit {
        try? group.syncShutdownGracefully()
    }
    
    public func connect() throws -> EventLoopFuture<Void> {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                let handler = Handler(clientID: self.clientID,
                                      cleanSession: self.cleanSession,
                                      keepAlive: self.keepAlive)
                handler.delegate = self
                return channel.pipeline.addHandler(handler)
            }
        let future: EventLoopFuture<Channel>
        switch domain {
        case let .ip(host, port):
            future = bootstrap.connect(host: host, port: port)
        case let .unix(path):
            future = bootstrap.connect(unixDomainSocketPath: path)
        }
        return future.map { channel in
            self.channel = channel
            let data = ConnectPacket(clientID: self.clientID,
                                     cleanSession: self.cleanSession,
                                     keepAliveSec: self.keepAlive).encodedData
            channel.writeAndFlush(ByteBuffer(bytes: data), promise: nil)
        }
    }
    
    public var isActive: Bool {
        channel?.isActive ?? false
    }
    
    public var closeFuture: EventLoopFuture<Void>? {
        channel?.closeFuture
    }
}

extension MQTTClient: HandlerDelegate {
    func didReceive<P: MQTTRecvPacket>(packet: P) {
        delegate?.didReceive(packet: packet)
    }
}
