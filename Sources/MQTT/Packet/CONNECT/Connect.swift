import Foundation

final class ConnectPacket: MQTTPacket {
    let clientID: String
    let cleanSession: Bool
    let will: WillMessage?
    let username: String?
    let password: String?
    let keepAlive: UInt16

    init(
        clientID: String,
        cleanSession: Bool,
        will: WillMessage?,
        username: String?,
        password: String?,
        keepAlive: UInt16
    ) {
        self.clientID = clientID
        self.cleanSession = cleanSession
        self.will = will
        self.username = username
        self.password = password
        self.keepAlive = keepAlive
        super.init(packetType: .connect, flags: 0)
    }

    struct WillMessage {
        let topic: String
        let payload: Data
        let retain: Bool
        let qos: QoS
    }

    var variableHeader: VariableHeader {
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
        return VariableHeader(flags: flags, keepAlive: keepAlive)
    }

    var payload: Payload {
        Payload(clientID: clientID, will: will, username: username, password: password)
    }

    override func encode() -> Data {
        encode(variableHeader: variableHeader, payload: payload)
    }
}

extension ConnectPacket {
    struct VariableHeader: DataEncodable {
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
        let flags: Flags
        let keepAlive: UInt16

        func encode() -> Data {
            var data = Data()
            data.write(protocolName)
            data.write(protocolLevel)
            data.write(flags.rawValue)
            data.write(keepAlive)
            return data
        }
    }

    struct Payload: DataEncodable {
        let clientID: String
        let will: WillMessage?
        let username: String?
        let password: String?

        func encode() -> Data {
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
}
