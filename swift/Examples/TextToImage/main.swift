import Buble

let client = try BubleClient.fromEnvironment()

let task = try await client.generations.create(
    try CreateGenerationRequest(model: "google/nano-banana")
        .mode("text_to_image")
        .prompt("A cinematic product photo of a matte black espresso cup")
        .param("aspect_ratio", "1:1")
        .param("output_format", "png")
)

let result = try await client.generations.wait(task.data.id)
print(result.data.result?.images?.first?.url.absoluteString ?? "")
