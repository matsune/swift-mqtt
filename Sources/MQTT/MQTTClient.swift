import Foundation
import NIO
import NIOSSL

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
    func mqttClient(_ client: MQTTClient, didCatchError error: Error)
}

public extension MQTTClientDelegate {
    var delegateDispatchQueue: DispatchQueue {
        .main
    }

    func mqttClient(_: MQTTClient, didReceive _: MQTTPacket) {}

    func mqttClient(_: MQTTClient, didChange _: ConnectionState) {}

    func mqttClient(_: MQTTClient, didCatchError _: Error) {}
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
    public var tlsConfiguration: TLSConfiguration?
    public var connectTimeout: Int64

    public weak var delegate: MQTTClientDelegate?

    private let group: EventLoopGroup

    private var _nextPacketIdentifier: UInt16 = 0
    private let lockQueue = DispatchQueue(label: "_nextPacketIdentifier")

    private var timeoutSchedule: Scheduled<Void>?
    private var pingTask: RepeatedTask?

    public init(
        host: String,
        port: Int,
        clientID: String = "",
        cleanSession: Bool,
        keepAlive: UInt16,
        willMessage: PublishMessage? = nil,
        username: String? = nil,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        connectTimeout: Int64 = 5
    ) {
        self.host = host
        self.port = port
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.keepAlive = keepAlive
        self.willMessage = willMessage
        self.username = username
        self.password = password
        self.connectTimeout = connectTimeout
        self.tlsConfiguration = tlsConfiguration
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    private var channelState: ChannelState = .disconnected {
        didSet {
            switch channelState {
            case .disconnected:
                cancelPingTimer()
            case .connectingChannel:
                break
            case .connectingBroker:
                break
            case .connected:
                cancelTimeoutTimer()
                startPingTimer()
            }
            let connectionState = channelState.connectionState
            delegate?.delegateDispatchQueue.async {
                self.delegate?.mqttClient(self, didChange: connectionState)
            }
        }
    }

    public var state: ConnectionState {
        channelState.connectionState
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

    private func createSSLHandler() throws -> NIOSSLClientHandler? {
        guard let tlsConfiguration = tlsConfiguration else {
            return nil
        }
        let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
        return try NIOSSLClientHandler(context: sslContext, serverHostname: host)
    }

    private func createMQTTHandler() -> MQTTChannelHandler {
        let mqttHandler = MQTTChannelHandler(clientID: clientID,
                                             cleanSession: cleanSession,
                                             keepAlive: keepAlive)
        mqttHandler.delegate = self
        return mqttHandler
    }

    private func connectChannnel() -> EventLoopFuture<Channel> {
        do {
            let mqttHandler = createMQTTHandler()
            let handlers: [ChannelHandler]
            if let sslHandler = try createSSLHandler() {
                handlers = [sslHandler, mqttHandler]
            } else {
                handlers = [mqttHandler]
            }
            return ClientBootstrap(group: group)
                .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                .channelInitializer { $0.pipeline.addHandlers(handlers) }
                .connect(host: host, port: port)
        } catch {
            return group.next().makeFailedFuture(error)
        }
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
        pingTask = group.next()
            .scheduleRepeatedTask(initialDelay: .seconds(Int64(keepAlive)), delay: .seconds(Int64(keepAlive))) { [weak self] _ in
                guard let self = self else { return }
                self.send(packet: PingReqPacket()).whenFailure {
                    self.throwErrorToDelegate($0, disconnect: true)
                }
            }
    }

    private func cancelPingTimer() {
        pingTask?.cancel()
        pingTask = nil
    }

    /// Check connection and send MQTT packet to connecting channel.
    /// Fail if channel is not connected.
    private func send(packet: MQTTPacket) -> EventLoopFuture<Void> {
        switch channelState {
        case let .connected(channel):
            return writeAndFlush(channel: channel, packet: packet)
        default:
            return group.next().makeFailedFuture(MQTTError.notConnected)
        }
    }

    private func writeAndFlush(channel: Channel, packet: MQTTPacket) -> EventLoopFuture<Void> {
        let bytes = packet.encode()
        return channel.writeAndFlush(ByteBuffer(bytes: bytes))
    }

    public func connect() {
        switch channelState {
        case .connected:
            break
        case .connectingChannel:
            throwErrorToDelegate(MQTTError.channelConnectPending, disconnect: true)
        case .connectingBroker:
            throwErrorToDelegate(MQTTError.brokerConnectPending, disconnect: true)
        case .disconnected:
            startTimeoutTimer()
            channelState = .connectingChannel
            connectChannnel()
                .whenFailure {
                    self.throwErrorToDelegate($0, disconnect: true)
                }
        }
    }

    private func startTimeoutTimer() {
        timeoutSchedule = group.next()
            .scheduleTask(deadline: .now() + .seconds(connectTimeout)) { [weak self] in
                self?.throwErrorToDelegate(MQTTError.connectTimeout, disconnect: true)
            }
    }

    private func cancelTimeoutTimer() {
        timeoutSchedule?.cancel()
        timeoutSchedule = nil
    }

    private func throwErrorToDelegate(_ error: Error, disconnect: Bool) {
        delegate?.delegateDispatchQueue.async {
            self.delegate?.mqttClient(self, didCatchError: error)
        }
        if disconnect {
            self.disconnect()
        }
    }

    public func disconnect() {
        switch channelState {
        case .connectingChannel:
            channelState = .disconnected
        case let .connectingBroker(channel):
            channel.close()
                .whenComplete {
                    self.channelState = .disconnected
                    if case let .failure(error) = $0 {
                        self.throwErrorToDelegate(error, disconnect: false)
                    }
                }
        case let .connected(channel):
            writeAndFlush(channel: channel, packet: DisconnectPacket())
                .flatMap { channel.close() }
                .whenComplete {
                    self.channelState = .disconnected
                    if case let .failure(error) = $0 {
                        self.throwErrorToDelegate(error, disconnect: false)
                    }
                }
        case .disconnected:
            break
        }
    }

    public func publish(message: PublishMessage, identifier: UInt16? = nil) {
        publish(topic: message.topic, retain: message.retain, qos: message.qos, payload: message.payload, identifier: identifier)
    }

    public func publish(topic: String, retain: Bool, qos: QoS, payload: DataEncodable, identifier: UInt16? = nil) {
        let id: UInt16?
        if qos == .atMostOnce {
            id = nil
        } else {
            id = identifier ?? nextPacketIdentifier()
        }
        let packet = PublishPacket(topic: topic, identifier: id, retain: retain, qos: qos, payload: payload.encode())
        send(packet: packet).whenFailure {
            self.throwErrorToDelegate($0, disconnect: true)
        }
    }

    public func subscribe(topic: String, qos: QoS, identifier: UInt16? = nil) {
        subscribe(topicFilter: TopicFilter(topic: topic, qos: qos), identifier: identifier)
    }

    public func subscribe(topicFilter: TopicFilter, identifier _: UInt16? = nil) {
        subscribe(topicFilters: [topicFilter])
    }

    public func subscribe(topicFilters: [TopicFilter], identifier: UInt16? = nil) {
        let packet = SubscribePacket(identifier: identifier ?? nextPacketIdentifier(),
                                     topicFilters: topicFilters)
        send(packet: packet).whenFailure {
            self.throwErrorToDelegate($0, disconnect: true)
        }
    }

    public func unsubscribe(topic: String, identifier: UInt16? = nil) {
        unsubscribe(topics: [topic], identifier: identifier)
    }

    public func unsubscribe(topics: [String], identifier: UInt16? = nil) {
        let packet = UnsubscribePacket(identifier: identifier ?? nextPacketIdentifier(), topicFilters: topics)
        send(packet: packet).whenFailure {
            self.throwErrorToDelegate($0, disconnect: true)
        }
    }
}

extension MQTTClient: MQTTChannelHandlerDelegate {
    func didReceive(packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            if case let .connectingBroker(channel) = channelState {
                if packet.returnCode == .accepted {
                    self.channelState = .connected(channel)
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
        throwErrorToDelegate(MQTTError.decodeError(error), disconnect: false)
    }

    func channelActive(channel: Channel) {
        switch channelState {
        case .connectingChannel:
            channelState = .connectingBroker(channel)
            connectBroker(channel: channel).whenFailure { self.throwErrorToDelegate($0, disconnect: true) }
        default:
            break
        }
    }

    func channelInactive() {
        disconnect()
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
}
