# swift-mqtt

Asyncronous MQTT client library using [SwiftNIO](https://github.com/apple/swift-nio) for networking layer.

- Based on [MQTT Version 3.1.1 Specification](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718028).
- Support SSL/TLS connection

## Usage

Create an instance of `MQTTClient` with parameters for connection.

```swift
let client = MQTTClient(
    host: "localhost",
    port: 1883,
    clientID: "swift-mqtt client",
    cleanSession: true,
    keepAlive: 30,
    willMessage: PublishMessage(topic: "will", payload: "will msg", retain: false, qos: .atMostOnce),
)
client.connect()
```

You can handle events by delegate methods.

```swift
client.delegate = self

...

// MQTTClientDelegate

func mqttClient(_ client: MQTTClient, didReceive packet: MQTTPacket) {
    ...
}

func mqttClient(_ client: MQTTClient, didChange state: ConnectionState) {
    ...
}

func mqttClient(_ client: MQTTClient, didCatchError error: Error) {
    ...
}
```

### Publish

```swift
client.publish(topic: "topic", retain: false, qos: QOS.0, payload: "payload")
```

### Subscribe

```swift
client.subscribe(topic: "topic", qos: QOS.0)
```

### Unsubscribe

```swift
client.unsubscribe(topic: "topic")
```

### Disconnect

```swift
client.disconnect()
```

## SSL/TLS connection

This library uses [SwiftNIO SSL](https://github.com/apple/swift-nio-ssl) for SSL connection. You can configure settings of client.

```swift
let caCert = "./server/certs/ca/ca_cert.pem"
let clientCert = "./server/certs/client/client_cert.pem"
let keyCert = "./server/certs/client/private/client_key.pem"
let tlsConfiguration = try? TLSConfiguration.forClient(
    minimumTLSVersion: .tlsv11,
    maximumTLSVersion: .tlsv12,
    certificateVerification: .noHostnameVerification,
    trustRoots: NIOSSLTrustRoots.certificates(NIOSSLCertificate.fromPEMFile(caCert)),
    certificateChain: NIOSSLCertificate.fromPEMFile(clientCert).map { .certificate($0) },
    privateKey: .privateKey(.init(file: keyCert, format: .pem))
)

client.tlsConfiguration = tlsConfiguration
```
