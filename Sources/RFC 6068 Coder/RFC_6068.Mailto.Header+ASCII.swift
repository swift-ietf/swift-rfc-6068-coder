public import ASCII
public import Binary
public import Byte
public import RFC_6068
import Coder
import Cursor
import Parser
import Serializer

extension RFC_6068.Mailto.Header: @retroactive ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        var input = ArraySlice(bytes)
        self = try RFC_6068.Mailto.Header.coder.parse(&input)
        guard input.isEmpty else {
            throw Error.trailingInput(Scan.text(Array(input)))
        }
    }
}

extension RFC_6068.Mailto.Header: @retroactive ASCII.Serializable, @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        var bytes: [Byte] = []
        Self.serialize(value, into: &bytes)
        buffer.append(contentsOf: bytes.lazy.map { ASCII.Code(unchecked: $0) })
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        Scan.serialize(value, into: &buffer)
    }
}

extension RFC_6068.Mailto.Header: @retroactive CustomStringConvertible {

    public var description: String {
        String(ascii: self)
    }
}
