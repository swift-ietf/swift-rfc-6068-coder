import Byte
import Byte
import Coder
import Coder
import Cursor
import Parser
import RFC_5322
import RFC_6068
import RFC_6068_Coder
import Testing

@Suite
struct `RFC_6068.Mailto Coder Tests` {

    @Test
    func `parses a single recipient`() throws {
        var input: ArraySlice<Byte> = "mailto:chris@example.com"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["chris@example.com"])
        #expect(mailto.headers.isEmpty)
        #expect(input.isEmpty)
    }

    @Test
    func `parses a subject header`() throws {
        var input: ArraySlice<Byte> = "mailto:infobot@example.com?subject=current-issue"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["infobot@example.com"])
        #expect(mailto.subject == "current-issue")
    }

    @Test
    func `decodes a percent-encoded body`() throws {
        var input: ArraySlice<Byte> = "mailto:infobot@example.com?body=send%20current-issue"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.body == "send current-issue")
    }

    @Test
    func `parses several headers separated by ampersands`() throws {
        var input: ArraySlice<Byte> = "mailto:user@example.com?subject=Test&body=Hello"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.subject == "Test")
        #expect(mailto.body == "Hello")
    }

    @Test
    func `parses comma-separated recipients`() throws {
        var input: ArraySlice<Byte> = "mailto:user1@example.com,user2@example.com"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["user1@example.com", "user2@example.com"])
    }

    @Test
    func `parses headers without any path recipient`() throws {
        var input: ArraySlice<Byte> = "mailto:?to=user@example.com&subject=Test"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.isEmpty)
        #expect(mailto.allTo.map(\.address) == ["user@example.com"])
        #expect(mailto.subject == "Test")
    }

    @Test
    func `a percent-encoded comma inside a quoted local part stays one recipient`() throws {
        var input: ArraySlice<Byte> = "mailto:%22ab%2Ccd%22@example.com"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["\"ab,cd\"@example.com"])
    }

    @Test
    func `a literal comma still separates recipients beside an encoded one`() throws {
        var input: ArraySlice<Byte> = "mailto:a@example.com,%22x%2Cy%22@example.org"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["a@example.com", "\"x,y\"@example.org"])
    }

    @Test
    func `the scheme reads case-insensitively`() throws {
        var input: ArraySlice<Byte> = "MAILTO:chris@example.com"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.to.map(\.address) == ["chris@example.com"])
    }

    @Test
    func `stops at whitespace and at a fragment`() throws {
        var input: ArraySlice<Byte> = "mailto:chris@example.com?subject=Hi#top rest"
        let mailto = try RFC_6068.Mailto.coder.parse(&input)
        #expect(mailto.subject == "Hi")
        #expect(input == "#top rest")
    }

    @Test
    func `rejects empty input`() {
        var input: ArraySlice<Byte> = ""
        #expect(throws: RFC_6068.Mailto.Error.empty) {
            try RFC_6068.Mailto.coder.parse(&input)
        }
    }

    @Test
    func `rejects a missing scheme and restores the cursor`() {
        var input: ArraySlice<Byte> = "user@example.com"
        #expect(throws: RFC_6068.Mailto.Error.missingScheme("user@example.com")) {
            try RFC_6068.Mailto.coder.parse(&input)
        }
        #expect(input == "user@example.com")
    }

    @Test
    func `rejects a recipient that is not a mailbox and restores the cursor`() {
        var input: ArraySlice<Byte> = "mailto:not-a-mailbox"
        #expect(throws: RFC_6068.Mailto.Error.invalidEmailAddress("not-a-mailbox")) {
            try RFC_6068.Mailto.coder.parse(&input)
        }
        #expect(input == "mailto:not-a-mailbox")
    }

    @Test
    func `rejects a header without an equals sign`() {
        var input: ArraySlice<Byte> = "mailto:chris@example.com?subject"
        #expect(throws: RFC_6068.Mailto.Error.self) {
            try RFC_6068.Mailto.coder.parse(&input)
        }
        #expect(input == "mailto:chris@example.com?subject")
    }

    @Test
    func `serializes recipients and headers with percent-encoding`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("user@example.com")],
            headers: [try .subject("Hello World"), try .body("Message content")]
        )
        var bytes132: [Byte] = []
        try RFC_6068.Mailto.coder.serialize(mailto, into: &bytes132)
        #expect(bytes132 == "mailto:user@example.com?subject=Hello%20World&body=Message%20content")
    }

    @Test
    func `serializes only the addr-spec of a recipient with a display name`() throws {
        let mailto = RFC_6068.Mailto(to: [try RFC_5322.Mailbox("Jane Doe <jane@example.com>")])
        var bytes138: [Byte] = []
        try RFC_6068.Mailto.coder.serialize(mailto, into: &bytes138)
        #expect(bytes138 == "mailto:jane@example.com")
    }

    @Test
    func `serializes several recipients separated by commas`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("a@example.com"), try RFC_5322.Mailbox("b@example.com")]
        )
        var bytes146: [Byte] = []
        try RFC_6068.Mailto.coder.serialize(mailto, into: &bytes146)
        #expect(bytes146 == "mailto:a@example.com,b@example.com")
    }

    @Test
    func `round-trips through its text form`() throws {
        let mailto = RFC_6068.Mailto(
            to: [try RFC_5322.Mailbox("Jane Doe <jane@example.com>")],
            headers: [try .subject("Hello World & more"), try .cc("manager@example.com")]
        )
        var bytes155: [Byte] = []
        try RFC_6068.Mailto.coder.serialize(mailto, into: &bytes155)
        var input = bytes155[...]
        let reparsed = try RFC_6068.Mailto.coder.parse(&input)
        #expect(reparsed.to.map(\.address) == ["jane@example.com"])
        #expect(reparsed.subject == "Hello World & more")
        #expect(reparsed.cc.map(\.address) == ["manager@example.com"])
        #expect(input.isEmpty)
    }
}
