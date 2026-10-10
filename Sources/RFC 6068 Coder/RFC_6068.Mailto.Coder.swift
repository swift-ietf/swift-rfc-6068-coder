public import Byte
public import Coder
public import Cursor
public import Cursor
public import RFC_6068
import Parser
import RFC_5322
import Serializer

extension RFC_6068.Mailto {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {


        public typealias Output = RFC_6068.Mailto

        public typealias Failure = RFC_6068.Mailto.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint

            guard Scan.consume(caseInsensitive: "mailto:", &input) else {
                let bytes = Scan.run(&input) { byte in !Scan.isTerminator(byte) }
                input.seek(to: start)
                guard !bytes.isEmpty else { throw .empty }
                throw .missingScheme(Scan.text(bytes))
            }

            let path = Scan.run(&input) { byte in
                byte.bitPattern != 0x3F && !Scan.isTerminator(byte)
            }

            var to: [RFC_5322.Mailbox] = []
            for segment in path.split(whereSeparator: { $0.bitPattern == 0x2C }) {
                let text = Scan.decoded(Array(segment))
                do throws(RFC_5322.Mailbox.Error) {
                    to.append(try RFC_5322.Mailbox(text))
                } catch {
                    input.seek(to: start)
                    throw .invalidEmailAddress(text)
                }
            }

            var headers: [RFC_6068.Mailto.Header] = []
            if Scan.consume(Byte(bitPattern: 0x3F), &input) {
                while true {
                    if Scan.consume(Byte(bitPattern: 0x26), &input) { continue }
                    let mark = input.checkpoint
                    guard let byte = input.next(), !Scan.isTerminator(byte) else {
                        input.seek(to: mark)
                        break
                    }
                    input.seek(to: mark)
                    do throws(RFC_6068.Mailto.Header.Error) {
                        headers.append(try RFC_6068.Mailto.Header.Coder<Input, Buffer>().parse(&input))
                    } catch {
                        input.seek(to: start)
                        throw .invalidHeader(error.description)
                    }
                }
            }

            return RFC_6068.Mailto(to: to, headers: headers)
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            Scan.serialize(output, into: &buffer)
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}
