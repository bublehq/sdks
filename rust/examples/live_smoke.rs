use buble::{Client, Result};
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let models = client.media_models().list(Some("image")).await?;
    println!(
        "{}",
        json!({ "step": "media_models", "count": models.data.len() })
    );

    let chat = client
        .chat()
        .completions()
        .create(json!({
            "model": "openai/gpt-5.4",
            "messages": [
                { "role": "user", "content": "Reply with exactly: Buble Rust SDK live smoke OK" }
            ],
            "max_completion_tokens": 32
        }))
        .await?;

    println!(
        "{}",
        json!({
            "step": "chat",
            "message": chat
                .pointer("/choices/0/message/content")
                .and_then(serde_json::Value::as_str)
                .unwrap_or_default()
        })
    );

    Ok(())
}
