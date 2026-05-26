use std::time::Duration;

use buble::{Client, CreateGenerationRequest, Result, WaitOptions};

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let task = client
        .generations()
        .create(
            CreateGenerationRequest::new("gork/grok-imagine-video")
                .mode("text_to_video")
                .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
                .param("duration", "5s")?
                .param("resolution", "480p")?
                .param("aspect_ratio", "16:9")?,
        )
        .await?;

    let result = client
        .generations()
        .wait(
            &task.data.id,
            WaitOptions::new()
                .interval(Duration::from_secs(2))
                .timeout(Duration::from_secs(900)),
        )
        .await?;

    if let Some(result) = result.data.result {
        if let Some(video) = result.videos.first() {
            println!("{}", video.url);
        }
    }

    Ok(())
}
