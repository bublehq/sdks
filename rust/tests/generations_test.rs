use std::time::Duration;

use buble::{Client, CreateGenerationRequest, Error, WaitOptions};
use serde_json::json;
use wiremock::{
    matchers::{body_json, method, path},
    Mock, MockServer, ResponseTemplate,
};

#[tokio::test]
async fn creates_flat_generation_body() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/api/v1/generations"))
        .and(body_json(json!({
            "model": "google/nano-banana",
            "mode": "text_to_image",
            "prompt": "A product image",
            "aspect_ratio": "1:1",
            "output_format": "png"
        })))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": { "id": "task_1", "status": "pending" }
        })))
        .mount(&server)
        .await;

    let client = client(&server);
    let task = client
        .generations()
        .create(
            CreateGenerationRequest::new("google/nano-banana")
                .mode("text_to_image")
                .prompt("A product image")
                .param("aspect_ratio", "1:1")
                .expect("aspect ratio")
                .param("output_format", "png")
                .expect("output format"),
        )
        .await
        .expect("task");

    assert_eq!(task.data.id, "task_1");
}

#[test]
fn rejects_internal_generation_fields() {
    let error = CreateGenerationRequest::new("google/nano-banana")
        .param("options", json!({ "duration": "5s" }))
        .expect_err("unsupported field");

    assert!(matches!(
        error,
        Error::UnsupportedGenerationField { ref field } if field == "options"
    ));
}

#[tokio::test]
async fn waits_until_success() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/api/v1/generations/task%5F1"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": {
                "id": "task_1",
                "status": "success",
                "result": { "images": [{ "url": "https://example.com/image.png" }] }
            }
        })))
        .mount(&server)
        .await;

    let client = client(&server);
    let result = client
        .generations()
        .wait(
            "task_1",
            WaitOptions::new()
                .interval(Duration::from_millis(1))
                .timeout(Duration::from_secs(1)),
        )
        .await
        .expect("success");

    assert_eq!(
        result.data.result.unwrap().images[0].url,
        "https://example.com/image.png"
    );
}

#[tokio::test]
async fn raises_on_failed_generation() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/api/v1/generations/task%5F1"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": {
                "id": "task_1",
                "status": "failed",
                "error": { "message": "provider failed" }
            }
        })))
        .mount(&server)
        .await;

    let client = client(&server);
    let error = client
        .generations()
        .wait(
            "task_1",
            WaitOptions::new().interval(Duration::from_millis(1)),
        )
        .await
        .expect_err("failed generation");

    assert!(matches!(
        error,
        Error::GenerationFailed { ref message, .. } if message == "provider failed"
    ));
}

fn client(server: &MockServer) -> Client {
    Client::builder()
        .api_key("sk_test")
        .base_url(server.uri())
        .build()
        .expect("client")
}
