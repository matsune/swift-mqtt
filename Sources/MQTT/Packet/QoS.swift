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
