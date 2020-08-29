@testable import MQTT
import NIOSSL
import XCTest

final class MQTTTests: XCTestCase {
    private var client: MQTTClient!
    
    private var didChangeCallback: (ConnectionState) -> Void = { _ in }

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
                            keepAlive: 30,
                            willMessage: nil,
                            username: "swift-mqtt",
                            password: "swift-mqtt",
                            tlsConfiguration: tlsConfiguration,
                            connectTimeout: 5)
        client.delegate = self
    }
    
    func testConnect() {
        let connect = expectation(description: "connect")
        didChangeCallback = { state in
            print(state)
            if state == .connected {
                connect.fulfill()
            }
        }
        client.connect()
        wait(for: [connect], timeout: 5)
    }
    
    static var allTests = [
        ("testConnect", testConnect),
    ]
}

extension MQTTTests: MQTTClientDelegate {
    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        didChangeCallback(state)
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        
    }
    
    func mqttClient(_: MQTTClient, didReceive _: MQTTPacket) {
        
    }
}
