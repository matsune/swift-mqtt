import MQTT
import Foundation

let sem = DispatchSemaphore(value: 0)

let queue = DispatchQueue(label: "a", qos: .background)

class App: MQTTClientDelegate {
    let client: MQTTClient
    
    var delegateDispatchQueue: DispatchQueue {
        queue
    }
    
    init() {
        client = MQTTClient(
            host: "localhost",
            port: 1883,
            clientID: "swift-mqtt",
            cleanSession: true,
            keepAlive: 30
        )
        client.delegate = self
    }
    
    func run() throws {
        client.connect()
    }
    
    func mqttClient(_ client: MQTTClient, didReceive packet: MQTTRecvPacket) {
        switch packet {
        case let packet as ConnAck:
            print("Connack \(packet)")
            client.publish(topic: "a", identifier: 1, retain: false, qos: .atLeastOnce, payload: "abc")
            queue.asyncAfter(deadline: .now() + 5) {
                self.client.disconnect()?.whenComplete({ res in
                    print("disconnect \(res) \(client.isConnected)")
                })
                sem.signal()
            }
        default:
            print(packet)
        }
    }
    
    func mqttClient(_: MQTTClient, didChange state: ConnectionState) {
        print(state)
    }
}

let app = App()
try app.run()

sem.wait()
