import ASCII
import Binary
import Byte
import RFC_5322
import RFC_6068
import RFC_6068_Coder
import Testing

@Suite
struct `Serialization Equivalence` {

    @Test
    func `Header serializes to its percent-encoded form through both verbs`() throws {
        let header = try RFC_6068.Mailto.Header(name: "a name", value: "Hello World & more")
        var ascii: [ASCII.Code] = []
        RFC_6068.Mailto.Header.serialize(header, into: &ascii)

        #expect(ascii.map(\.byte) == [Byte](utf8: "a%20name=Hello%20World%20%26%20more"))
        #expect([Byte](header) == [Byte](utf8: "a%20name=Hello%20World%20%26%20more"))
        #expect(header.description == "a%20name=Hello%20World%20%26%20more")
    }

    @Test
    func `Mailto serializes to its URI form through both verbs`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("Jane Doe <jane@example.com>")],
            headers: [try .subject("Hello World & more")]
        )
        var ascii: [ASCII.Code] = []
        RFC_6068.Mailto.serialize(mailto, into: &ascii)

        #expect(ascii.map(\.byte) == [Byte](utf8: "mailto:jane@example.com?subject=Hello%20World%20%26%20more"))
        #expect([Byte](mailto) == [Byte](utf8: "mailto:jane@example.com?subject=Hello%20World%20%26%20more"))
        #expect(mailto.description == "mailto:jane@example.com?subject=Hello%20World%20%26%20more")
    }

    @Test
    func `Mailto reads back from its ASCII bytes`() throws {
        let mailto = try RFC_6068.Mailto(ascii: [Byte](utf8: "mailto:chris@example.com?subject=Hi"))
        #expect(mailto.to.map(\.address) == ["chris@example.com"])
        #expect(mailto.subject == "Hi")
    }

    @Test
    func `trailing bytes after the URI are rejected`() {
        #expect(throws: RFC_6068.Mailto.Error.trailingInput(" rest")) {
            try RFC_6068.Mailto(ascii: [Byte](utf8: "mailto:chris@example.com rest"))
        }
    }
}
