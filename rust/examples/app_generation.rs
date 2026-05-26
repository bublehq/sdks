use buble::{Client, ListAppsParams, Result, WaitOptions};
use serde_json::{json, Map};

#[tokio::main]
async fn main() -> Result<()> {
    let client = Client::from_env()?;

    let apps = client.apps().list(ListAppsParams::new().limit(20)).await?;
    println!("{} apps available", apps.data.len());

    let body = json!({
        "source_video": ["https://example.com/source.mp4"],
        "refine_foreground_edges": true,
        "subject_is_person": true
    });
    let body: Map<String, serde_json::Value> = body.as_object().expect("object body").clone();

    let task = client
        .apps()
        .generations()
        .create("video-background-remover", body)
        .await?;

    let result = client
        .apps()
        .generations()
        .wait(
            "video-background-remover",
            &task.data.id,
            WaitOptions::default(),
        )
        .await?;
    println!("{result:#?}");

    Ok(())
}
