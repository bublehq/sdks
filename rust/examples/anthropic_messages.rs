use buble::{Client, Result};
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let message = client
        .chat()
        .messages()
        .create(json!({
            "model": "openai/gpt-5.4",
            "system": "You are concise.",
            "messages": [
                { "role": "user", "content": "Summarize this release." }
            ],
            "max_tokens": 800
        }))
        .await?;

    println!("{message:#?}");
    Ok(())
}
