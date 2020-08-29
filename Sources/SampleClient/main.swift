import Foundation
import MQTT
import NIOSSL

let base: String
if CommandLine.arguments.count > 1 {
    base = CommandLine.arguments[1]
} else {
    base = "."
}

let sem = DispatchSemaphore(value: 0)
let queue = DispatchQueue(label: "a", qos: .background)

class App: MQTTClientDelegate {
    let client: MQTTClient

    var delegateDispatchQueue: DispatchQueue {
        queue
    }

    init() {
        let caCert = "\(base)/server/mosquitto/certs/ca/ca_cert.pem"
        let clientCert = "\(base)/server/mosquitto/certs/client/client_cert.pem"
        let keyCert = "\(base)/server/mosquitto/certs/client/private/client_key.pem"
        let tlsConfiguration = try! TLSConfiguration.forClient(minimumTLSVersion: .tlsv11,
                                                               maximumTLSVersion: .tlsv12,
                                                               certificateVerification: .noHostnameVerification,
                                                               trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
                                                               certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
                                                               privateKey: .privateKey(.init(file: keyCert, format: .pem)))
        client = MQTTClient(
            host: "localhost",
            port: 8883,
            clientID: "swift-mqtt client",
            cleanSession: true,
            keepAlive: 30,
            willMessage: PublishMessage(topic: "will", payload: "will msg", retain: false, qos: .atMostOnce),
            username: "swift-mqtt",
            password: "swift-mqtt",
            tlsConfiguration: tlsConfiguration
        )
        client.tlsConfiguration = tlsConfiguration
        client.delegate = self
    }

    func run() throws {
        client.connect()
    }

    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
        switch packet {
        case let packet as ConnAckPacket:
            print("Connack \(packet)")
            client.subscribe(topic: "a", qos: QOS.0)
            client.publish(topic: "a", retain: false, qos: QOS.0, payload: "abc")
            queue.asyncAfter(deadline: .now() + 40) {
                self.client.disconnect()
            }
        default:
            print(packet)
        }
    }

    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        if state == .disconnected {
            sem.signal()
        }
        print(state)
    }

    func mqttClient(_: MQTTClient, didCatchError error: Error) {
        print("Error: \(error)")
    }
}

let app = App()
try app.run()

sem.wait()
