import Foundation

public protocol DataEncodable {
    func encode() -> Data
}

extension Data: DataEncodable {
    public func encode() -> Data {
        self
    }
}
