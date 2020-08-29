@testable import MQTT
import NIOSSL
import XCTest

final class MQTTTests: XCTestCase {
    private var client: MQTTClient!

    private var didChangeStateCallback: (ConnectionState) -> Void = { _ in }
    private var didReceivePacketCallback: (MQTTPacket) -> Void = { _ in }

    override func setUp() {
        let caCert = "./server/mosquitto/certs/ca/ca_cert.pem"
        let clientCert = "./server/mosquitto/certs/client/client_cert.pem"
        let keyCert = "./server/mosquitto/certs/client/private/client_key.pem"
        let tlsConfiguration = try! TLSConfiguration.forClient(minimumTLSVersion: .tlsv11,
                                                               maximumTLSVersion: .tlsv12,
                                                               certificateVerification: .noHostnameVerification,
                                                               trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
                                                               certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
                                                               privateKey: .privateKey(.init(file: keyCert, format: .pem)))
        client = MQTTClient(host: "localhost",
                            port: 8883,
                            clientID: "MQTTTests",
                            cleanSession: true,
                            keepAlive: 60,
                            willMessage: nil,
                            username: "swift-mqtt",
                            password: "swift-mqtt",
                            tlsConfiguration: tlsConfiguration,
                            connectTimeout: 5)
        client.delegate = self
        
        let connect = expectation(description: "connect")
        didChangeStateCallback = { state in
            if state == .connected {
                connect.fulfill()
            }
        }
        client.connect()
        wait(for: [connect], timeout: 5)
    }
    
    override func tearDown() {
        client.disconnect()
        client = nil
    }
    
    func testSubscribe() {
        let subscribe = expectation(description: "subscribe")
        let identifier: UInt16 = 10
        didReceivePacketCallback = { packet in
            switch packet {
            case let packet as SubAckPacket:
                XCTAssert(packet.identifier == identifier, "identifier, \(packet.identifier) != \(identifier)")
                let returnCodes: [SubAckPacket.ReturnCode] = [.success(.atMostOnce)]
                XCTAssert(packet.returnCodes == returnCodes, "return codes, \(packet.returnCodes) != \(returnCodes)")
                subscribe.fulfill()
            default:
                break
            }
        }
        client.subscribe(topic: "test", qos: .atMostOnce, identifier: identifier)
        wait(for: [subscribe], timeout: 5)
    }

    static var allTests = [
        ("testSubscribe", testSubscribe),
    ]
}

extension MQTTTests: MQTTClientDelegate {
    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        didChangeStateCallback(state)
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        XCTFail("\(error)")
    }

    func mqttClient(_: MQTTClient, didReceive packet: MQTTPacket) {
        didReceivePacketCallback(packet)
    }
}
