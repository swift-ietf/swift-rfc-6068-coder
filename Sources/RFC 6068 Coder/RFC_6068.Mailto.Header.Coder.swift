public import Byte
public import Coder
public import Cursor
public import Cursor
public import RFC_6068
import Parser
import Serializer

extension RFC_6068.Mailto.Header {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {


        public typealias Output = RFC_6068.Mailto.Header

        public typealias Failure = RFC_6068.Mailto.Header.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            let bytes = Scan.run(&input) { byte in
                byte.bitPattern != 0x26 && !Scan.isTerminator(byte)
            }

            guard !bytes.isEmpty else {
                throw .empty
            }

            guard let equals = bytes.firstIndex(where: { $0.bitPattern == 0x3D }) else {
                input.seek(to: start)
                throw .missingEquals(Scan.text(bytes))
            }

            let name = Array(bytes[..<equals])
            guard !name.isEmpty else {
                input.seek(to: start)
                throw .emptyName(Scan.text(bytes))
            }

            do throws(Failure) {
                return try RFC_6068.Mailto.Header(
                    name: Scan.decoded(name),
                    value: Scan.decoded(Array(bytes[(equals + 1)...]))
                )
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            Scan.serialize(output, into: &buffer)
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}
