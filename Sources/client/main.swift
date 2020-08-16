import MQTT
import Foundation

class App: MQTTClientDelegate {
    func run() throws {
        let client = MQTTClient(domain: .ip(host: "localhost", port: 8883),
                                clientID: "swift-mqtt",
                                cleanSession: true,
                                keepAlive: 30)
        client.delegate = self
        do {
            try client.connect().whenSuccess {
                print("sent connect", client.isActive)
            }
        } catch {
            print("error: \(error)")
        }
        RunLoop.current.run()
    }
    
    func didReceive<Packet>(packet: Packet) where Packet : MQTTRecvPacket {
        switch packet {
        case let packet as ConnackPacket:
            print(packet)
        default:
            print(packet)
        }
    }
}

try App().run()
