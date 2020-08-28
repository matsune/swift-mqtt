public enum MQTTError: Error {
    case channelConnectPending
    case brokerConnectPending
    case notConnected
    case connectTimeout
    case decodeError(DecodeError)
}

public enum DecodeError: Error {
    case malformedData
    case malformedQoS
    case malformedPacketType
    case malformedConnAckReturnCode
    case malformedSubAckReturnCode
}
