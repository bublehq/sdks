use buble::{Client, Result};
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let completion = client
        .chat()
        .completions()
        .create(json!({
            "model": "openai/gpt-5.4",
            "messages": [
                { "role": "user", "content": "Write a short launch summary." }
            ],
            "max_completion_tokens": 800
        }))
        .await?;

    println!("{completion:#?}");
    Ok(())
}
