import Buble

let client = try BubleClient.fromEnvironment()

let uploaded = try await client.files.upload(
    .fromFileURL(URL(fileURLWithPath: "reference.png"), contentType: "image/png"),
    options: UploadOptions(
        fileType: "image",
        model: "google/nano-banana",
        mode: "image_to_image"
    )
)

let task = try await client.generations.create(
    CreateGenerationRequest(model: "google/nano-banana")
        .mode("image_to_image")
        .prompt("Turn this reference into a polished ecommerce hero image.")
        .imageURLs([uploaded.data.url.absoluteString])
)

let result = try await client.generations.wait(task.data.id)
print(result.data.result?.images?.first?.url.absoluteString ?? "")
