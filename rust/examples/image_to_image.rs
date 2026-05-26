use buble::{Client, CreateGenerationRequest, FileUpload, Result, UploadOptions, WaitOptions};

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let uploaded = client
        .files()
        .upload(
            FileUpload::from_path("reference.png").content_type("image/png"),
            UploadOptions::new()
                .file_type("image")
                .model("google/nano-banana")
                .mode("image_to_image"),
        )
        .await?;

    let task = client
        .generations()
        .create(
            CreateGenerationRequest::new("google/nano-banana")
                .mode("image_to_image")
                .prompt("Turn this reference into a polished ecommerce hero image.")
                .image_urls([uploaded.data.url]),
        )
        .await?;

    let result = client
        .generations()
        .wait(&task.data.id, WaitOptions::default())
        .await?;
    println!("{result:#?}");

    Ok(())
}
