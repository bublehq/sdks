/// Request body for creating an asynchronous media generation task.
public struct CreateGenerationRequest: Sendable {
    public var model: String
    public var mode: String?
    public var prompt: String?
    public var imageURLs: [String]
    public var startFrame: String?
    public var endFrame: String?
    public var videoURLs: [String]
    public var audioURLs: [String]
    public var isPublic: Bool?
    public var copyProtected: Bool?
    public var parameters: [String: JSONValue]

    public init(model: String) {
        self.model = model
        self.imageURLs = []
        self.videoURLs = []
        self.audioURLs = []
        self.parameters = [:]
    }

    public func mode(_ value: String) -> CreateGenerationRequest {
        var copy = self
        copy.mode = value
        return copy
    }

    public func prompt(_ value: String) -> CreateGenerationRequest {
        var copy = self
        copy.prompt = value
        return copy
    }

    public func imageURLs(_ value: [String]) -> CreateGenerationRequest {
        var copy = self
        copy.imageURLs = value
        return copy
    }

    public func startFrame(_ value: String) -> CreateGenerationRequest {
        var copy = self
        copy.startFrame = value
        return copy
    }

    public func endFrame(_ value: String) -> CreateGenerationRequest {
        var copy = self
        copy.endFrame = value
        return copy
    }

    public func videoURLs(_ value: [String]) -> CreateGenerationRequest {
        var copy = self
        copy.videoURLs = value
        return copy
    }

    public func audioURLs(_ value: [String]) -> CreateGenerationRequest {
        var copy = self
        copy.audioURLs = value
        return copy
    }

    public func isPublic(_ value: Bool) -> CreateGenerationRequest {
        var copy = self
        copy.isPublic = value
        return copy
    }

    public func copyProtected(_ value: Bool) -> CreateGenerationRequest {
        var copy = self
        copy.copyProtected = value
        return copy
    }

    public func param(_ key: String, _ value: JSONValue) throws -> CreateGenerationRequest {
        try Self.assertSupportedField(key)
        var copy = self
        copy.parameters[key] = value
        return copy
    }

    func body() throws -> JSONValue {
        var object: [String: JSONValue] = ["model": .string(model)]
        if let mode, !mode.isEmpty { object["mode"] = .string(mode) }
        if let prompt, !prompt.isEmpty { object["prompt"] = .string(prompt) }
        if !imageURLs.isEmpty { object["image_urls"] = .array(imageURLs.map { .string($0) }) }
        if let startFrame, !startFrame.isEmpty { object["start_frame"] = .string(startFrame) }
        if let endFrame, !endFrame.isEmpty { object["end_frame"] = .string(endFrame) }
        if !videoURLs.isEmpty { object["video_urls"] = .array(videoURLs.map { .string($0) }) }
        if !audioURLs.isEmpty { object["audio_urls"] = .array(audioURLs.map { .string($0) }) }
        if let isPublic { object["is_public"] = .bool(isPublic) }
        if let copyProtected { object["copy_protected"] = .bool(copyProtected) }

        for (key, value) in parameters {
            try Self.assertSupportedField(key)
            object[key] = value
        }
        for key in object.keys {
            try Self.assertSupportedField(key)
        }
        return .object(object)
    }

    static func assertSupportedField(_ field: String) throws {
        if forbiddenFields.contains(field) {
            throw BubleError.unsupportedGenerationField(field: field)
        }
    }

    private static let forbiddenFields: Set<String> = [
        "input",
        "options",
        "scene",
        "sub_mode_id",
        "subModeId",
        "provider",
        "mediaType",
        "media_type",
        "images",
        "image_input",
        "video_input",
        "audio_input"
    ]
}
