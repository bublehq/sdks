use buble::Client;
use serde_json::json;
use wiremock::{
    matchers::{header, method, path},
    Mock, MockServer, ResponseTemplate,
};

#[tokio::test]
async fn sends_authorization_header_and_lists_media_models() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/api/v1/media_models"))
        .and(header("authorization", "Bearer sk_test"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": [
                { "model": "google/nano-banana", "media_type": "image", "operations": [] }
            ]
        })))
        .mount(&server)
        .await;

    let client = Client::builder()
        .api_key("sk_test")
        .base_url(server.uri())
        .build()
        .expect("client");

    let response = client.media_models().list(None).await.expect("models");

    assert_eq!(response.data[0].model, "google/nano-banana");
}

#[test]
fn rejects_missing_api_key() {
    let error = Client::builder()
        .api_key("")
        .build()
        .expect_err("missing key");
    assert!(error.to_string().contains("missing Buble API key"));
}
