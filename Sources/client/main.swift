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
            clientID: "a",
            cleanSession: true,
            keepAlive: 10,
            willMessage: PublishMessage(topic: "will msg", payload: "willl me", retain: false, qos: .atMostOnce)
        )
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
            queue.asyncAfter(deadline: .now() + 60) {
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

