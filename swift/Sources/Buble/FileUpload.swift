/// File source for uploads to Buble.
public enum FileUpload: Sendable {
    case data(Data, filename: String, contentType: String)
    case fileURL(URL, filename: String? = nil, contentType: String? = nil)

    public static func fromData(_ data: Data, filename: String, contentType: String = "application/octet-stream") -> FileUpload {
        .data(data, filename: filename, contentType: contentType)
    }

    public static func fromFileURL(_ url: URL, filename: String? = nil, contentType: String? = nil) -> FileUpload {
        .fileURL(url, filename: filename, contentType: contentType)
    }

    func multipartBody(fields: [String: String]) throws -> MultipartBody {
        let boundary = "BubleBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        var body = Data()

        for (name, value) in fields where !value.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(escape(name))\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        let fileData: Data
        let filename: String
        let contentType: String
        switch self {
        case .data(let data, let name, let type):
            fileData = data
            filename = name
            contentType = type
        case .fileURL(let url, let name, let type):
            fileData = try Data(contentsOf: url)
            filename = name ?? url.lastPathComponent
            contentType = type ?? Self.inferContentType(filename)
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(escape(filename))\"\r\n")
        body.append("Content-Type: \(contentType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")

        return MultipartBody(body: body, contentType: "multipart/form-data; boundary=\(boundary)")
    }

    private static func inferContentType(_ filename: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "webp": return "image/webp"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "webm": return "video/webm"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        default: return "application/octet-stream"
        }
    }

    private func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}

struct MultipartBody {
    let body: Data
    let contentType: String
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
