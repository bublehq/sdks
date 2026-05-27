/// Common response envelope for media, file, and app endpoints.
public struct Envelope<T: Codable & Sendable>: Codable, Sendable {
    public let data: T
}

extension Envelope: Equatable where T: Equatable {}

/// Lifecycle status for asynchronous generation tasks.
public enum TaskStatus: String, Codable, Equatable, Sendable {
    case pending
    case processing
    case success
    case failed
    case canceled
    case unknown

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = TaskStatus(rawValue: value) ?? .unknown
    }

    public var isTerminal: Bool {
        self == .success || self == .failed || self == .canceled
    }
}

public struct MediaModel: Codable, Equatable, Sendable {
    public let model: String
    public let name: String?
    public let mediaType: String?
    public let operations: [MediaModelOperation]

    enum CodingKeys: String, CodingKey {
        case model
        case name
        case mediaType = "media_type"
        case operations
    }
}

public struct MediaModelOperation: Codable, Equatable, Sendable {
    public let mode: String
    public let description: String?
    public let input: JSONValue?
    public let parameters: [MediaModelParameter]
}

public struct MediaModelParameter: Codable, Equatable, Sendable {
    public let name: String
    public let type: String?
    public let label: String?
    public let defaultValue: JSONValue?
    public let values: [JSONValue]?
    public let required: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case label
        case defaultValue = "default"
        case values
        case required
    }
}

public struct UploadedFile: Codable, Equatable, Sendable {
    public let object: String
    public let provider: String
    public let url: URL
    public let key: String
    public let fileType: String
    public let contentType: String
    public let size: Int
    public let filename: String

    enum CodingKeys: String, CodingKey {
        case object
        case provider
        case url
        case key
        case fileType = "file_type"
        case contentType = "content_type"
        case size
        case filename
    }
}

public struct MediaResultImage: Codable, Equatable, Sendable {
    public let url: URL
}

public struct MediaResultVideo: Codable, Equatable, Sendable {
    public let url: URL
    public let previewURL: URL?
    public let thumbnailURL: URL?
    public let duration: JSONValue?

    enum CodingKeys: String, CodingKey {
        case url
        case previewURL = "preview_url"
        case thumbnailURL = "thumbnail_url"
        case duration
    }
}

public struct MediaResultAudio: Codable, Equatable, Sendable {
    public let url: URL
    public let imageURL: URL?
    public let title: String?
    public let duration: JSONValue?

    enum CodingKeys: String, CodingKey {
        case url
        case imageURL = "image_url"
        case title
        case duration
    }
}

public struct GenerationResult: Codable, Equatable, Sendable {
    public let images: [MediaResultImage]?
    public let videos: [MediaResultVideo]?
    public let audios: [MediaResultAudio]?
}

public struct GenerationTaskError: Codable, Equatable, Sendable {
    public let code: String?
    public let message: String?
}

public struct GenerationTask: Codable, Equatable, Sendable {
    public let id: String
    public let status: TaskStatus
    public let model: String?
    public let mediaType: String?
    public let mode: String?
    public let costCredits: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let result: GenerationResult?
    public let error: GenerationTaskError?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case model
        case mediaType = "media_type"
        case mode
        case costCredits = "cost_credits"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case result
        case error
    }
}

public struct PublicApp: Codable, Equatable, Sendable {
    public let id: String
    public let inputParameters: [AppInputParameter]

    enum CodingKeys: String, CodingKey {
        case id
        case inputParameters = "input_parameters"
    }
}

public struct AppInputParameter: Codable, Equatable, Sendable {
    public let name: String
    public let type: String
    public let values: [JSONValue]?
}

public struct AppGenerationTask: Codable, Equatable, Sendable {
    public let id: String
    public let status: TaskStatus
    public let result: GenerationResult?
    public let error: GenerationTaskError?
}

public struct ChatModel: Codable, Equatable, Sendable {
    public let id: String
    public let object: String
    public let created: Int?
    public let ownedBy: String?
    public let name: String?
    public let description: String?
    public let capabilities: [String: JSONValue]?
    public let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
        case name
        case description
        case capabilities
        case tags
    }
}

public struct ChatModelList: Codable, Equatable, Sendable {
    public let object: String
    public let data: [ChatModel]
}
