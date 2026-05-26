use buble::{Client, Result};
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let response = client
        .chat()
        .gemini()
        .generate_content(
            "openai/gpt-5.4",
            json!({
                "contents": [
                    {
                        "role": "user",
                        "parts": [
                            { "text": "Write a short launch summary." }
                        ]
                    }
                ]
            }),
        )
        .await?;

    println!("{response:#?}");
    Ok(())
}
