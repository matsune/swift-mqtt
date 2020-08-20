public enum QoS: UInt8 {
    case atMostOnce = 0
    case atLeastOnce = 1
    case exactlyOnce = 2
}

public let QOS = (QoS.atMostOnce, QoS.atLeastOnce, QoS.exactlyOnce)
