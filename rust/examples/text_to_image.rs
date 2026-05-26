use buble::{Client, CreateGenerationRequest, Result, WaitOptions};

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let task = client
        .generations()
        .create(
            CreateGenerationRequest::new("google/nano-banana")
                .mode("text_to_image")
                .prompt("A cinematic product photo of a matte black espresso cup")
                .param("aspect_ratio", "1:1")?
                .param("output_format", "png")?,
        )
        .await?;

    let result = client
        .generations()
        .wait(&task.data.id, WaitOptions::default())
        .await?;

    if let Some(result) = result.data.result {
        if let Some(image) = result.images.first() {
            println!("{}", image.url);
        }
    }

    Ok(())
}
