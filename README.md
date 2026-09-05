# swift-rfc-6068-coder

Wire coders for [swift-rfc-6068](https://github.com/swift-ietf/swift-rfc-6068): `RFC_6068.Mailto.Coder` and `RFC_6068.Mailto.Header.Coder` parse and serialize the mailto URI text form (percent-encoded addr-specs and header fields per RFC 6068 and RFC 3986) over any byte cursor, `Coder.Codable` gives both `encoded()` and `init(decoding:)`, and the `ASCII.Parseable`, `ASCII.Serializable` and `Binary.Serializable` conformances live here so that the domain package stays a pure model.
