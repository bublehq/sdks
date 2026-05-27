/// Optional upload validation fields.
public struct UploadOptions: Sendable {
    public var fileType: String?
    public var model: String?
    public var mode: String?

    public init(fileType: String? = nil, model: String? = nil, mode: String? = nil) {
        self.fileType = fileType
        self.model = model
        self.mode = mode
    }
}

/// Source media upload methods.
public struct FilesService: Sendable {
    let http: BubleHTTPClient

    /// Uploads an image, video, or audio file for use as generation input.
    public func upload(_ file: FileUpload, options: UploadOptions = UploadOptions()) async throws -> Envelope<UploadedFile> {
        var fields: [String: String] = [:]
        if let fileType = options.fileType { fields["file_type"] = fileType }
        if let model = options.model { fields["model"] = model }
        if let mode = options.mode { fields["mode"] = mode }
        return try await http.requestMultipart("/api/v1/files", fields: fields, file: file)
    }
}
