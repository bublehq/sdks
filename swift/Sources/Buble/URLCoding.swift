enum URLCoding {
    static func encodePathSegment(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: pathSegmentAllowed) ?? value
    }

    static func encodeModelPath(_ value: String) -> String {
        value.split(separator: "/", omittingEmptySubsequences: false)
            .map { encodePathSegment(String($0)) }
            .joined(separator: "/")
    }

    private static let pathSegmentAllowed: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()
}
