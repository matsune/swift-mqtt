/// # Reference
/// [Quality of Service levels and protocol flows](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718099)
public enum QoS: UInt8 {
    case atMostOnce = 0
    case atLeastOnce = 1
    case exactlyOnce = 2

    init(value: UInt8) throws {
        guard let qos = QoS(rawValue: value) else {
            throw DecodeError.malformedQoS
        }
        self = qos
    }
}

public let QOS = (QoS.atMostOnce, QoS.atLeastOnce, QoS.exactlyOnce)
