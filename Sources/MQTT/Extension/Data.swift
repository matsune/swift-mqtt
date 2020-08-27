import Foundation

extension Data {
    /// Append 8bit data.
    mutating func write(_ data: UInt8) {
        var data = data
        append(&data, count: 1)
    }

    /// Append 16 bits integer value in big-endian order.
    mutating func write(_ data: UInt16) {
        let msb = UInt8(data / 256)
        let lsb = UInt8(data % 256)
        append(contentsOf: [msb, lsb])
    }

    /// Append string value encoded as UTF-8 prefixed with 16 bits length field.
    mutating func write(_ string: String) {
        write(UInt16(string.count))
        append(contentsOf: string.utf8)
    }

    mutating func advance(_ bytes: Int) {
        if count <= bytes {
            self = Data()
        } else {
            self = advanced(by: bytes)
        }
    }

    mutating func read1ByteInt() -> UInt8 {
        let value = self[0]
        advance(1)
        return value
    }

    /// Read 16 bits integer value ordered by big-endian and advance 2 bytes.
    mutating func read2BytesInt() -> UInt16 {
        let value = UInt16(self[0]) << 8 | UInt16(self[1])
        advance(2)
        return value
    }

    /// Read and advance n-bytes.
    mutating func read(bytes: Int) -> Data {
        let m = Swift.min(bytes, count)
        let data = subdata(in: 0 ..< m)
        advance(bytes)
        return data
    }

    /// Read and advance n-bytes.
    mutating func read(bytes: UInt16) -> Data {
        return read(bytes: Int(bytes))
    }

    /// Check remain size before read and advance.
    func hasSize(_ size: UInt16) -> Bool {
        count >= size
    }
}
