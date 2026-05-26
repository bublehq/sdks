use std::time::Duration;

use buble::{Client, ListAppsParams, WaitOptions};
use serde_json::{json, Map, Value};
use wiremock::{
    matchers::{body_json, method, path, query_param},
    Mock, MockServer, ResponseTemplate,
};

#[tokio::test]
async fn lists_and_retrieves_apps() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/api/v1/apps"))
        .and(query_param("limit", "20"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": [
                {
                    "id": "video-background-remover",
                    "input_parameters": [{ "name": "source_video", "type": "array" }]
                }
            ]
        })))
        .mount(&server)
        .await;

    let apps = client(&server)
        .apps()
        .list(ListAppsParams::new().limit(20))
        .await
        .expect("apps");

    assert_eq!(apps.data[0].id, "video-background-remover");
}

#[tokio::test]
async fn creates_and_waits_for_app_generation() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path(
            "/api/v1/apps/video%2Dbackground%2Dremover/generations",
        ))
        .and(body_json(
            json!({ "source_video": ["https://example.com/source.mp4"] }),
        ))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": { "id": "task_1", "status": "pending" }
        })))
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path(
            "/api/v1/apps/video%2Dbackground%2Dremover/generations/task%5F1",
        ))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": {
                "id": "task_1",
                "status": "success",
                "result": { "videos": [{ "url": "https://example.com/video.mp4" }] }
            }
        })))
        .mount(&server)
        .await;

    let client = client(&server);
    let mut body = Map::<String, Value>::new();
    body.insert(
        "source_video".to_string(),
        json!(["https://example.com/source.mp4"]),
    );

    let task = client
        .apps()
        .generations()
        .create("video-background-remover", body)
        .await
        .expect("create");
    let result = client
        .apps()
        .generations()
        .wait(
            "video-background-remover",
            &task.data.id,
            WaitOptions::new()
                .interval(Duration::from_millis(1))
                .timeout(Duration::from_secs(1)),
        )
        .await
        .expect("wait");

    assert_eq!(
        result.data.result.unwrap().videos[0].url,
        "https://example.com/video.mp4"
    );
}

fn client(server: &MockServer) -> Client {
    Client::builder()
        .api_key("sk_test")
        .base_url(server.uri())
        .build()
        .expect("client")
}
