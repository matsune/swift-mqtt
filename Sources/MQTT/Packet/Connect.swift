import Foundation

public struct ConnectVariableHeader: DataEncodable {
    struct Flags: OptionSet {
        let rawValue: UInt8
        
        static let cleanSession = Flags(rawValue: 1 << 1)
        static let will = Flags(rawValue: 1 << 2)
        static func qos(_ qos: QoS) -> Flags {
            Flags(rawValue: qos.rawValue << 3)
        }
        static let willRetain = Flags(rawValue: 1 << 5)
        static let hasUsername = Flags(rawValue: 1 << 6)
        static let hasPassword = Flags(rawValue: 1 << 7)
    }
    
    let protocolName: String = "MQTT"
    let protocolLevel: UInt8 = 0x04
    // Flags
    let flags: Flags
    // Keep Alive
    let keepAliveSec: UInt16

    public var encodedData: Data {
        var data = Data()
        data.write(protocolName)
        data.write(protocolLevel)
        data.write(flags.rawValue)
        data.write(keepAliveSec)
        return data
    }
}

public struct Message {
    let topic: String
    let payload: Data
    let retain: Bool
    let qos: QoS
    
    init(topic: String, payload: Data, retain: Bool, qos: QoS) {
        self.topic = topic
        self.payload = payload
        self.retain = retain
        self.qos = qos
    }
}


public struct ConnectPayload: DataEncodable {
    let clientID: String
    let will: Message?
    let username: String?
    let password: String?
    
    public var encodedData: Data {
        var data = Data()
        data.write(clientID)
        if let will = will {
            data.write(will.topic)
            data.append(will.payload)
        }
        if let username = username {
            data.write(username)
        }
        if let password = password {
            data.write(password)
        }
        return data
    }
}

public class ConnectPacket: MQTTSendPacket {
    public typealias VariableHeader = ConnectVariableHeader
    public typealias Payload = ConnectPayload
    
    public let fixedHeader: FixedHeader
    public var clientID: String
    public var cleanSession: Bool
    public var will: Message?
    public var username: String?
    public var password: String?
    public var keepAliveSec: UInt16

    public init(
          clientID: String = "",
          cleanSession: Bool = true,
          will: Message? = nil,
          username: String? = nil,
          password: String? = nil,
          keepAliveSec: UInt16
      ) {
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.will = will
        self.username = username
        self.password = password
        self.keepAliveSec = keepAliveSec
        self.fixedHeader = FixedHeader(packetType: .connect, flags: 0)
    }
    
    public var variableHeader: VariableHeader? {
        var flags: VariableHeader.Flags = []
        if cleanSession {
            flags.insert(.cleanSession)
        }
        if let will = will {
            flags.insert(.will)
            flags.insert(.qos(will.qos))
            if will.retain {
                flags.insert(.willRetain)
            }
        }
        if username != nil {
            flags.insert(.hasUsername)
        }
        if password != nil {
            flags.insert(.hasPassword)
        }
        return VariableHeader(flags: flags, keepAliveSec: keepAliveSec)
    }
    
    public var payload: ConnectPayload? {
        ConnectPayload(clientID: clientID, will: will, username: username, password: password)
    }
}
