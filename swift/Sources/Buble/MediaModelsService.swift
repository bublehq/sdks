/// Media model discovery methods.
public struct MediaModelsService: Sendable {
    let http: BubleHTTPClient

    /// Lists API-ready media models.
    public func list(mediaType: String? = nil) async throws -> Envelope<[MediaModel]> {
        let query = mediaType.map { [URLQueryItem(name: "media_type", value: $0)] } ?? []
        return try await http.request("GET", "/api/v1/media_models", query: query)
    }
}
