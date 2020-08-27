import Foundation
import NIO

public enum ConnectionState {
    case disconnected
    case connectingChannel
    case connectingBroker
    case connected
}

public protocol MQTTClientDelegate: AnyObject {
    var delegateDispatchQueue: DispatchQueue { get }

    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket)
    func mqttClient(_ client: MQTTClient, didChange state: ConnectionState)
    func mqttClient(_ client: MQTTClient, didCatchDecodeError error: DecodeError)
}

public extension MQTTClientDelegate {
    var delegateDispatchQueue: DispatchQueue {
        .main
    }

    func mqttClient(_: MQTTClient, didReceive _: MQTTPacket) {}

    func mqttClient(_: MQTTClient, didChange _: ConnectionState) {}

    func mqttClient(_: MQTTClient, didCatchDecodeError _: DecodeError) {}
}

public class MQTTClient {
    public var host: String
    public var port: Int
    public var clientID: String
    public var cleanSession: Bool
    public var keepAlive: UInt16
    public var willMessage: PublishMessage?
    public var username: String?
    public var password: String?

    public weak var delegate: MQTTClientDelegate?

    private let group: EventLoopGroup

    private var keepAliveTimer: DispatchSourceTimer?

    private var _nextPacketIdentifier: UInt16 = 0
    private let lockQueue = DispatchQueue(label: "_nextPacketIdentifier")

    public init(
        host: String,
        port: Int,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16,
        willMessage: PublishMessage? = nil,
        username: String? = nil,
        password: String? = nil
    ) {
        self.host = host
        self.port = port
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.willMessage = willMessage
        self.username = username
        self.password = password
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    private var state: ChannelState = .disconnected {
        didSet {
            switch state {
            case .disconnected:
                invalidatePingTimer()
            case .connectingChannel:
                break
            case .connectingBroker:
                break
            case .connected:
                startPingTimer()
            }
            let connectionState = state.connectionState
            delegate?.delegateDispatchQueue.async {
                self.delegate?.mqttClient(self, didChange: connectionState)
            }
        }
    }

    private func nextPacketIdentifier() -> UInt16 {
        lockQueue.sync {
            if _nextPacketIdentifier == 0xFFFF {
                _nextPacketIdentifier = 0
            }
            _nextPacketIdentifier += 1
            return _nextPacketIdentifier
        }
    }

    private func connectChannnel() -> EventLoopFuture<Channel> {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                let handler = MQTTChannelHandler(clientID: self.clientID,
                                                 cleanSession: self.cleanSession,
                                                 keepAlive: self.keepAlive)
                handler.delegate = self
                return channel.pipeline.addHandler(handler)
            }
        return bootstrap.connect(host: host, port: port)
    }

    private func connectBroker(channel: Channel) -> EventLoopFuture<Void> {
        let packet = ConnectPacket(clientID: clientID,
                                   cleanSession: cleanSession,
                                   will: willMessage,
                                   username: username,
                                   password: password,
                                   keepAlive: keepAlive)
        return writeAndFlush(channel: channel, packet: packet)
    }

    private func startPingTimer() {
        keepAliveTimer?.cancel()
        keepAliveTimer = DispatchSource.makeTimerSource()
        keepAliveTimer?.schedule(deadline: .now() + .seconds(Int(keepAlive)),
                                 repeating: .seconds(Int(keepAlive)),
                                 leeway: .seconds(1))
        keepAliveTimer?.setEventHandler(handler: { [weak self] in
            _ = self?.send(packet: PingReqPacket())
        })
        keepAliveTimer?.resume()
    }

    private func invalidatePingTimer() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
    }

    private func send(packet: MQTTPacket) -> EventLoopFuture<Void> {
        switch state {
        case let .connected(channel):
            return writeAndFlush(channel: channel, packet: packet)
        default:
            return group.next().makeFailedFuture(Error.notConnected)
        }
    }

    private func writeAndFlush(channel: Channel, packet: MQTTPacket) -> EventLoopFuture<Void> {
        let bytes = packet.encode()
        return channel.writeAndFlush(ByteBuffer(bytes: bytes))
            .always {
                if case .failure = $0 {
                    self.disconnect()
                }
            }
    }

    @discardableResult
    public func connect() -> EventLoopFuture<Void> {
        switch state {
        case .connected:
            return group.next().makeSucceededFuture(())
        case .connectingChannel:
            return group.next().makeFailedFuture(Error.channelConnectPending)
        case .connectingBroker:
            return group.next().makeFailedFuture(Error.brokerConnectPending)
        case .disconnected:
            state = .connectingChannel
            return connectChannnel()
                .flatMap { channel in
                    self.state = .connectingBroker(channel)
                    return self.connectBroker(channel: channel)
                }
        }
    }

    @discardableResult
    public func disconnect() -> EventLoopFuture<Void> {
        switch state {
        case .connectingChannel:
            state = .disconnected
            return group.next().makeSucceededFuture(())
        case let .connectingBroker(channel):
            return channel
                .close()
                .always { _ in self.state = .disconnected }
        case let .connected(channel):
            return writeAndFlush(channel: channel, packet: DisconnectPacket())
                .flatMap { channel.close() }
                .always { _ in self.state = .disconnected }
        case .disconnected:
            return group.next().makeSucceededFuture(())
        }
    }

    public func publish(message: PublishMessage, identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        return publish(topic: message.topic, retain: message.retain, qos: message.qos, payload: message.payload, identifier: identifier)
    }

    public func publish(topic: String, retain: Bool, qos: QoS, payload: DataEncodable, identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        let id: UInt16?
        if qos == .atMostOnce {
            id = nil
        } else {
            id = identifier ?? nextPacketIdentifier()
        }
        let packet = PublishPacket(topic: topic, identifier: id, retain: retain, qos: qos, payload: payload.encode())
        return send(packet: packet)
    }

    public func subscribe(topic: String, qos: QoS, identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        return subscribe(topicFilter: TopicFilter(topic: topic, qos: qos), identifier: identifier)
    }

    public func subscribe(topicFilter: TopicFilter, identifier _: UInt16? = nil) -> EventLoopFuture<Void>? {
        return subscribe(topicFilters: [topicFilter])
    }

    public func subscribe(topicFilters: [TopicFilter], identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        let packet = SubscribePacket(identifier: identifier ?? nextPacketIdentifier(),
                                     topicFilters: topicFilters)
        return send(packet: packet)
    }

    public func unsubscribe(topic: String, identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        return unsubscribe(topics: [topic], identifier: identifier)
    }

    public func unsubscribe(topics: [String], identifier: UInt16? = nil) -> EventLoopFuture<Void>? {
        let packet = UnsubscribePacket(identifier: identifier ?? nextPacketIdentifier(), topicFilters: topics)
        return send(packet: packet)
    }
}

extension MQTTClient: MQTTChannelHandlerDelegate {
    func didReceive(packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            if case let .connectingBroker(channel) = state {
                if packet.returnCode == .accepted {
                    self.state = .connected(channel)
                } else {
                    disconnect()
                }
            }
        case let packet as PubRecPacket:
            let identifier = packet.identifier
            send(packet: PubRelPacket(identifier: identifier))
                .whenFailure { error in
                    print("failed to send PubRel packet: \(error.localizedDescription)")
                }
        default:
            break
        }
        delegate?.delegateDispatchQueue.async {
            self.delegate?.mqttClient(self, didReceive: packet)
        }
    }

    func didCatch(decodeError error: DecodeError) {
        delegate?.delegateDispatchQueue.async {
            self.delegate?.mqttClient(self, didCatchDecodeError: error)
        }
    }
}

extension MQTTClient {
    private enum ChannelState {
        case disconnected
        case connectingChannel
        case connectingBroker(Channel)
        case connected(Channel)

        var connectionState: ConnectionState {
            switch self {
            case .disconnected:
                return .disconnected
            case .connectingChannel:
                return .connectingChannel
            case .connectingBroker:
                return .connectingBroker
            case .connected:
                return .connected
            }
        }
    }

    public enum Error: Swift.Error {
        case channelConnectPending
        case brokerConnectPending
        case notConnected
    }
}
