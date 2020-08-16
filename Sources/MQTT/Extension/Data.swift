import Foundation

extension Data {
    mutating func write(_ data: UInt8) {
        var data = data
        append(&data, count: 1)
    }
    
    mutating func write(_ data: UInt16) {
        let msb = UInt8(data / 256)
        let lsb = UInt8(data % 256)
        append(contentsOf: [msb, lsb])
    }
    
    mutating func write(_ string: String) {
        write(UInt16(string.count))
        append(contentsOf: string.utf8)
    }
}
