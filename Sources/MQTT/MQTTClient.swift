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
    func didReceive<Packet: MQTTRecvPacket>(client: MQTTClient, packet: Packet)
}

public enum EventLoopGroupProvider {
    case shared(EventLoopGroup)
    case createNew
}

public class MQTTClient {
    public enum Domain {
        case ip(host: String, port: Int)
        case unix(path: String)
    }
    
    enum State {
        case disconnected
        case connecting(Channel)
        case connected(Channel)
    }
    
    public var domain: Domain
    public var clientID: String
    public var cleanSession: Bool
    public var keepAlive: UInt16

    public weak var delegate: MQTTClientDelegate?
    
    private let group: EventLoopGroup
    private var state: State = .disconnected
    
    public init(
        loopGroupProvider: EventLoopGroupProvider = .createNew,
        domain: Domain,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16
    ) {
        switch loopGroupProvider {
        case .createNew:
            self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        case let .shared(group):
            self.group = group
        }
        self.domain = domain
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
    }
    
    deinit {
        try? group.syncShutdownGracefully()
    }
    
    private func connectSocket() -> EventLoopFuture<Channel> {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                let handler = Handler(clientID: self.clientID,
                                      cleanSession: self.cleanSession,
                                      keepAlive: self.keepAlive)
                handler.delegate = self
                return channel.pipeline.addHandler(handler)
            }
        switch domain {
        case let .ip(host, port):
            return bootstrap.connect(host: host, port: port)
        case let .unix(path):
            return bootstrap.connect(unixDomainSocketPath: path)
        }
    }
    
    @discardableResult
    public func connect() -> EventLoopFuture<Void>? {
        guard !isConnected else {
            return nil
        }
        return connectSocket()
            .flatMap { channel in
                self.state = .connecting(channel)
                return self.writeAndFlush(channel: channel,
                                          packet: ConnectPacket(clientID: self.clientID,
                                                                cleanSession: self.cleanSession,
                                                                keepAliveSec: self.keepAlive))
            }
    }
    
    public var isConnected: Bool {
        switch state {
        case let .connected(channel):
            return channel.isActive
        default:
            return false
        }
    }
    
    var channel: Channel? {
        switch state {
        case let .connected(channel),
            let .connecting(channel):
            return channel
        default:
            return nil
        }
    }
    
    private func writeAndFlush<Packet: MQTTSendPacket>(channel: Channel, packet: Packet) -> EventLoopFuture<Void> {
        channel.writeAndFlush(ByteBuffer(bytes: packet.encodedData))
    }
    
    @discardableResult
    public func disconnect() -> EventLoopFuture<Void>? {
        switch state {
        case let .connecting(channel):
            return channel
                .close()
                .always { _ in self.state = .disconnected }
        case let .connected(channel):
            return writeAndFlush(channel: channel, packet: DisconnectPacket())
                .flatMap { channel.close() }
                .always { _ in self.state = .disconnected }
        case .disconnected:
            return nil
        }
        
    }
}

extension MQTTClient: HandlerDelegate {
    func didReceive<P: MQTTRecvPacket>(packet: P) {
        switch packet {
        case is ConnackPacket:
            switch state {
            case let .connecting(channel):
                self.state = .connected(channel)
            default:
                break
            }
        default:
            break
        }
        delegate?.didReceive(client: self, packet: packet)
    }
}
