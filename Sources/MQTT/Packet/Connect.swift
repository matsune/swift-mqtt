import Foundation

struct ConnectVariableHeader: DataEncodable {
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

    var encodedData: Data {
        var data = Data()
        data.write(protocolName)
        data.write(protocolLevel)
        data.write(flags.rawValue)
        data.write(keepAliveSec)
        return data
    }
}

struct Message {
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


struct ConnectPayload: DataEncodable {
    let clientID: String
    let will: Message?
    let username: String?
    let password: String?
    
    var encodedData: Data {
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

class ConnectPacket: MQTTSendPacket {
    typealias VariableHeader = ConnectVariableHeader
    typealias Payload = ConnectPayload
    
    let fixedHeader: FixedHeader
    var clientID: String
    var cleanSession: Bool
    var will: Message?
    var username: String?
    var password: String?
    var keepAliveSec: UInt16

    init(
          clientID: String,
          cleanSession: Bool,
          will: Message?,
          username: String?,
          password: String?,
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
    
    var variableHeader: VariableHeader? {
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
    
    var payload: ConnectPayload? {
        ConnectPayload(clientID: clientID, will: will, username: username, password: password)
    }
}
