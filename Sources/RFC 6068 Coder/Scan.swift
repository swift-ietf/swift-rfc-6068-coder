import Byte
import Cursor
import RFC_3986
import RFC_5322
import RFC_6068

enum Scan {

    static func run<Input: Cursor.`Protocol`<Byte, Never>>(
        _ input: inout Input,
        while predicate: (Byte) -> Bool
    ) -> [Byte] {
        var bytes: [Byte] = []
        while true {
            let mark = input.checkpoint
            guard let byte = input.next(), predicate(byte) else {
                input.seek(to: mark)
                return bytes
            }
            bytes.append(byte)
        }
    }

    static func consume<Input: Cursor.`Protocol`<Byte, Never>>(_ code: UInt8, _ input: inout Input) -> Bool {
        let mark = input.checkpoint
        guard let byte = input.next(), byte.bitPattern == code else {
            input.seek(to: mark)
            return false
        }
        return true
    }

    static func consume<Input: Cursor.`Protocol`<Byte, Never>>(
        caseInsensitive literal: String,
        _ input: inout Input
    ) -> Bool {
        let mark = input.checkpoint
        for expected in literal.utf8 {
            guard let byte = input.next(), Self.lowercased(byte.bitPattern) == Self.lowercased(expected) else {
                input.seek(to: mark)
                return false
            }
        }
        return true
    }

    static func lowercased(_ code: UInt8) -> UInt8 {
        (0x41...0x5A).contains(code) ? code + 0x20 : code
    }

    static func isTerminator(_ byte: Byte) -> Bool {
        let code = byte.bitPattern
        return code <= 0x20 || code == 0x7F || code == 0x23
    }

    static func text(_ bytes: [Byte]) -> String {
        String(decoding: bytes.lazy.map(\.bitPattern), as: UTF8.self)
    }

    static func decoded(_ bytes: [Byte]) -> String {
        String(decoding: RFC_3986.percentDecode(bytes.lazy.map(\.bitPattern)), as: UTF8.self)
    }

    static func encode<Buffer: RangeReplaceableCollection<Byte>>(
        _ string: String,
        allowing allowed: RFC_3986.ByteSet,
        into buffer: inout Buffer
    ) {
        buffer.append(
            contentsOf: RFC_3986.percentEncode(Array(string.utf8), allowing: allowed)
                .lazy.map(Byte.init(bitPattern:))
        )
    }

    static func append<Buffer: RangeReplaceableCollection<Byte>>(_ string: String, into buffer: inout Buffer) {
        buffer.append(contentsOf: string.utf8.lazy.map(Byte.init(bitPattern:)))
    }
}

extension Scan {

    static func serialize<Buffer: RangeReplaceableCollection<Byte>>(
        _ header: RFC_6068.Mailto.Header,
        into buffer: inout Buffer
    ) {
        Self.encode(header.name, allowing: .mailto.qchar, into: &buffer)
        buffer.append(Byte(bitPattern: 0x3D))
        Self.encode(header.value, allowing: .mailto.qchar, into: &buffer)
    }

    static func serialize<Buffer: RangeReplaceableCollection<Byte>>(
        _ mailto: RFC_6068.Mailto,
        into buffer: inout Buffer
    ) {
        Self.append("mailto:", into: &buffer)

        for (index, mailbox) in mailto.to.enumerated() {
            if index > 0 {
                buffer.append(Byte(bitPattern: 0x2C))
            }
            Self.encode(mailbox.address, allowing: .mailto.addrSpec, into: &buffer)
        }

        guard !mailto.headers.isEmpty else { return }
        buffer.append(Byte(bitPattern: 0x3F))

        for (index, header) in mailto.headers.enumerated() {
            if index > 0 {
                buffer.append(Byte(bitPattern: 0x26))
            }
            Self.serialize(header, into: &buffer)
        }
    }
}
