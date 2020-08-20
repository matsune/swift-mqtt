import Foundation
import NIO

protocol HandlerDelegate: AnyObject {
    func didReceive(packet: MQTTRecvPacket)
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

public enum ConnectionState {
    case disconnected
    case connecting
    case connected
}

public protocol MQTTClientDelegate: AnyObject {
    var delegateDispatchQueue: DispatchQueue { get }
    
    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTRecvPacket)
    func mqttClient(_ client: MQTTClient, didChange state: ConnectionState)
}

public extension MQTTClientDelegate {
    var delegateDispatchQueue: DispatchQueue {
        .main
    }

    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTRecvPacket){}
    func mqttClient(_ client: MQTTClient, didChange state: ConnectionState){}
}

public enum EventLoopGroupProvider {
    case shared(EventLoopGroup)
    case createNew
}

public class MQTTClient {
    public enum State {
        case disconnected
        case connecting(Channel)
        case connected(Channel)
    }
    
    public var host: String
    public var port: Int
    public var clientID: String
    public var cleanSession: Bool
    public var keepAlive: UInt16
    public var username: String?
    public var password: String?

    public weak var delegate: MQTTClientDelegate?
    
    private let group: EventLoopGroup
    
    public private(set) var state: State = .disconnected {
        didSet {
            delegate?.delegateDispatchQueue.async {
                switch self.state {
                case .disconnected:
                    self.onDisconnect()
                    self.delegate?.mqttClient(self, didChange: .disconnected)
                case .connecting:
                    self.delegate?.mqttClient(self, didChange: .connecting)
                case let .connected(channel):
                    self.onConnected()
                    self.delegate?.mqttClient(self, didChange: .connected)
                }
            }
        }
    }
    
    public init(
        host: String,
        port: Int,
        loopGroupProvider: EventLoopGroupProvider = .createNew,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16,
        username: String? = nil,
        password: String? = nil
    ) {
        self.host = host
        self.port = port
        switch loopGroupProvider {
        case .createNew:
            self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        case let .shared(group):
            self.group = group
        }
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.username = username
        self.password = password
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
        return bootstrap.connect(host: host, port: port)
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
                                                                will: nil,
                                                                username: self.username,
                                                                password: self.password,
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
    
    private var keepAliveTimer: DispatchSourceTimer?
    
    private func onConnected() {
        print("onConnected")
        keepAliveTimer?.cancel()
        keepAliveTimer = DispatchSource.makeTimerSource()
        keepAliveTimer?.schedule(deadline: .now() + Double(keepAlive), repeating: Double(keepAlive))
        keepAliveTimer?.setEventHandler(handler: { [weak self] in
            guard let channel = self?.channel else {
                return
            }
            _ = self?.writeAndFlush(channel: channel, packet: PingreqPacket())
        })
        keepAliveTimer?.resume()
    }
    
    private func onDisconnect() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
    }
    
    private func writeAndFlush<Packet: MQTTSendPacket>(channel: Channel, packet: Packet) -> EventLoopFuture<Void> {
        channel.writeAndFlush(ByteBuffer(bytes: packet.encode()))
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
    func didReceive(packet: MQTTRecvPacket) {
        switch packet {
        case let packet as ConnackPacket:
            if case let .connecting(channel) = state, packet.returnCode == .accepted {
                self.state = .connected(channel)
            } else {
                self.state = .disconnected
            }
        default:
            break
        }
        delegate?.delegateDispatchQueue.async {
            self.delegate?.mqttClient(self, didReceive: packet)
        }
    }
}
