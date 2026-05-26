use buble::{Client, FileUpload, UploadOptions};
use serde_json::json;
use wiremock::{
    matchers::{method, path},
    Mock, MockServer, ResponseTemplate,
};

#[tokio::test]
async fn uploads_multipart_file() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/api/v1/files"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "data": {
                "object": "file",
                "provider": "r2",
                "url": "https://example.com/source.png",
                "key": "api/image/source.png",
                "file_type": "image",
                "content_type": "image/png",
                "size": 3,
                "filename": "source.png"
            }
        })))
        .mount(&server)
        .await;

    let client = Client::builder()
        .api_key("sk_test")
        .base_url(server.uri())
        .build()
        .expect("client");

    let uploaded = client
        .files()
        .upload(
            FileUpload::from_bytes_with_content_type(vec![1_u8, 2, 3], "source.png", "image/png"),
            UploadOptions::new()
                .file_type("image")
                .model("google/nano-banana")
                .mode("image_to_image"),
        )
        .await
        .expect("upload");

    assert_eq!(uploaded.data.url, "https://example.com/source.png");
}
