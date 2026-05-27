import Buble

let client = try BubleClient.fromEnvironment()

let task = try await client.apps.generations.create(
    "video-background-remover",
    body: [
        "source_video": ["https://example.com/source.mp4"],
        "refine_foreground_edges": true,
        "subject_is_person": true
    ]
)

let result = try await client.apps.generations.wait("video-background-remover", task.data.id)
print(result.data.result?.videos?.first?.url.absoluteString ?? "")
