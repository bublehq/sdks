use buble::Client;
use futures_util::StreamExt;
use serde_json::json;
use wiremock::{
    matchers::{body_json, method, path},
    Mock, MockServer, ResponseTemplate,
};

#[tokio::test]
async fn creates_openai_chat_completion() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/api/v1/chat/completions"))
        .and(body_json(json!({
            "model": "openai/gpt-5.4",
            "messages": [{ "role": "user", "content": "Hi" }],
            "stream": false
        })))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "choices": [{ "message": { "content": "Hello" } }]
        })))
        .mount(&server)
        .await;

    let response = client(&server)
        .chat()
        .completions()
        .create(json!({
            "model": "openai/gpt-5.4",
            "messages": [{ "role": "user", "content": "Hi" }]
        }))
        .await
        .expect("chat");

    assert_eq!(
        response.pointer("/choices/0/message/content").unwrap(),
        "Hello"
    );
}

#[tokio::test]
async fn streams_openai_text() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/api/v1/chat/completions"))
        .respond_with(
            ResponseTemplate::new(200)
                .insert_header("content-type", "text/event-stream")
                .set_body_string("data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\ndata: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n\ndata: [DONE]\n\n"),
        )
        .mount(&server)
        .await;

    let mut stream = client(&server)
        .chat()
        .completions()
        .stream_text(json!({
            "model": "openai/gpt-5.4",
            "messages": [{ "role": "user", "content": "Hi" }]
        }))
        .await
        .expect("stream");

    let mut output = String::new();
    while let Some(chunk) = stream.next().await {
        output.push_str(&chunk.expect("chunk"));
    }

    assert_eq!(output, "Hello");
}

#[tokio::test]
async fn calls_gemini_model_path_without_escaping_slash() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path(
            "/api/v1beta/models/openai/gpt%2D5%2E4:generateContent",
        ))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({ "candidates": [] })))
        .mount(&server)
        .await;

    client(&server)
        .chat()
        .gemini()
        .generate_content("openai/gpt-5.4", json!({ "contents": [] }))
        .await
        .expect("gemini");
}

fn client(server: &MockServer) -> Client {
    Client::builder()
        .api_key("sk_test")
        .base_url(server.uri())
        .build()
        .expect("client")
}
