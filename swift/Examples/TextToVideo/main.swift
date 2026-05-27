import Buble

let client = try BubleClient.fromEnvironment()

let task = try await client.generations.create(
    try CreateGenerationRequest(model: "gork/grok-imagine-video")
        .mode("text_to_video")
        .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
        .param("duration", "5s")
        .param("resolution", "480p")
        .param("aspect_ratio", "16:9")
)

let result = try await client.generations.wait(
    task.data.id,
    options: WaitOptions(interval: 2, timeout: 900)
)
print(result.data.result?.videos?.first?.url.absoluteString ?? "")
