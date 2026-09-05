import Byte
import Byte_Standard_Library_Integration
import Coder
import Coder_Standard_Library_Integration
import Cursor_Standard_Library_Integration
import Parser
import RFC_6068
import RFC_6068_Coder
import Testing

@Suite
struct `RFC_6068.Mailto.Header Coder Tests` {

    @Test
    func `parses a name and a percent-decoded value`() throws {
        var input: ArraySlice<Byte> = "subject=Hello%20World"
        let header = try RFC_6068.Mailto.Header.coder.parse(&input)
        #expect(header.name == "subject")
        #expect(header.value == "Hello World")
        #expect(input.isEmpty)
    }

    @Test
    func `stops at the ampersand`() throws {
        var input: ArraySlice<Byte> = "subject=Test&body=Hello"
        let header = try RFC_6068.Mailto.Header.coder.parse(&input)
        #expect(header == (try .subject("Test")))
        #expect(input == "&body=Hello")
    }

    @Test
    func `a value may be empty`() throws {
        var input: ArraySlice<Byte> = "body="
        let header = try RFC_6068.Mailto.Header.coder.parse(&input)
        #expect(header.name == "body")
        #expect(header.value.isEmpty)
    }

    @Test
    func `a percent-encoded name is decoded`() throws {
        var input: ArraySlice<Byte> = "in%2Dreply%2Dto=%3Cid@example.com%3E"
        let header = try RFC_6068.Mailto.Header.coder.parse(&input)
        #expect(header.name == "in-reply-to")
        #expect(header.value == "<id@example.com>")
    }

    @Test
    func `rejects empty input`() {
        var input: ArraySlice<Byte> = ""
        #expect(throws: RFC_6068.Mailto.Header.Error.empty) {
            try RFC_6068.Mailto.Header.coder.parse(&input)
        }
    }

    @Test
    func `rejects a field without an equals sign and restores the cursor`() {
        var input: ArraySlice<Byte> = "subject"
        #expect(throws: RFC_6068.Mailto.Header.Error.missingEquals("subject")) {
            try RFC_6068.Mailto.Header.coder.parse(&input)
        }
        #expect(input == "subject")
    }

    @Test
    func `rejects an empty name and restores the cursor`() {
        var input: ArraySlice<Byte> = "=value"
        #expect(throws: RFC_6068.Mailto.Header.Error.emptyName("=value")) {
            try RFC_6068.Mailto.Header.coder.parse(&input)
        }
        #expect(input == "=value")
    }

    @Test
    func `serializes with percent-encoding outside qchar`() throws {
        let header = try RFC_6068.Mailto.Header(name: "a name", value: "Hello World & more")
        #expect(try header.encoded() == "a%20name=Hello%20World%20%26%20more")
    }

    @Test
    func `round-trips through its text form`() throws {
        let header = try RFC_6068.Mailto.Header.subject("Hello World & more")
        var input = try header.encoded()[...]
        #expect(try RFC_6068.Mailto.Header(decoding: &input) == header)
        #expect(input.isEmpty)
    }
}
