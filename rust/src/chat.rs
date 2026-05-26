use futures_util::StreamExt;
use reqwest::Method;
use serde_json::Value;

use crate::{
    client::Client,
    error::Result,
    http::encode_model_path,
    request::set_stream,
    streaming::{events_from_bytes, text_from_event, EventStream, StreamProtocol, TextStream},
    ChatModelList,
};

/// Flexible chat request body.
pub type ChatRequest = Value;

/// Protocol-native chat response body.
pub type ChatResponse = Value;

/// Chat model methods for OpenAI, Anthropic, and Gemini-compatible APIs.
#[derive(Clone, Debug)]
pub struct ChatService {
    client: Client,
}

impl ChatService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Chat model discovery methods.
    pub fn models(&self) -> ChatModelsService {
        ChatModelsService::new(self.client.clone())
    }

    /// OpenAI-compatible chat completions methods.
    pub fn completions(&self) -> ChatCompletionsService {
        ChatCompletionsService::new(self.client.clone())
    }

    /// Anthropic Messages-compatible methods.
    pub fn messages(&self) -> MessagesService {
        MessagesService::new(self.client.clone())
    }

    /// Gemini-compatible methods.
    pub fn gemini(&self) -> GeminiService {
        GeminiService::new(self.client.clone())
    }
}

/// Chat model discovery methods.
#[derive(Clone, Debug)]
pub struct ChatModelsService {
    client: Client,
}

impl ChatModelsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Lists active chat models.
    pub async fn list(&self) -> Result<ChatModelList> {
        self.client
            .request_json::<ChatModelList, ()>(Method::GET, "/api/v1/models", None, None)
            .await
    }
}

/// OpenAI-compatible chat completion methods.
#[derive(Clone, Debug)]
pub struct ChatCompletionsService {
    client: Client,
}

impl ChatCompletionsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Calls the OpenAI-compatible chat completions endpoint.
    pub async fn create(&self, mut body: ChatRequest) -> Result<ChatResponse> {
        set_stream(&mut body, false);
        self.client
            .request_value(Method::POST, "/api/v1/chat/completions", None, Some(&body))
            .await
    }

    /// Streams raw OpenAI-compatible server-sent events.
    pub async fn stream(&self, mut body: ChatRequest) -> Result<EventStream> {
        set_stream(&mut body, true);
        let bytes = self
            .client
            .stream_json(Method::POST, "/api/v1/chat/completions", Some(&body))
            .await?;
        Ok(events_from_bytes(bytes))
    }

    /// Streams extracted OpenAI-compatible text deltas.
    pub async fn stream_text(&self, body: ChatRequest) -> Result<TextStream> {
        let stream = self.stream(body).await?;
        Ok(Box::pin(stream.filter_map(|event| async move {
            match event {
                Ok(event) => {
                    let text = text_from_event(&event, StreamProtocol::OpenAi);
                    if text.is_empty() {
                        None
                    } else {
                        Some(Ok(text))
                    }
                }
                Err(error) => Some(Err(error)),
            }
        })))
    }
}

/// Anthropic Messages-compatible methods.
#[derive(Clone, Debug)]
pub struct MessagesService {
    client: Client,
}

impl MessagesService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Calls the Anthropic Messages-compatible endpoint.
    pub async fn create(&self, mut body: ChatRequest) -> Result<ChatResponse> {
        set_stream(&mut body, false);
        self.client
            .request_value(Method::POST, "/api/v1/messages", None, Some(&body))
            .await
    }

    /// Streams raw Anthropic-compatible server-sent events.
    pub async fn stream(&self, mut body: ChatRequest) -> Result<EventStream> {
        set_stream(&mut body, true);
        let bytes = self
            .client
            .stream_json(Method::POST, "/api/v1/messages", Some(&body))
            .await?;
        Ok(events_from_bytes(bytes))
    }

    /// Streams extracted Anthropic-compatible text deltas.
    pub async fn stream_text(&self, body: ChatRequest) -> Result<TextStream> {
        let stream = self.stream(body).await?;
        Ok(Box::pin(stream.filter_map(|event| async move {
            match event {
                Ok(event) => {
                    let text = text_from_event(&event, StreamProtocol::Anthropic);
                    if text.is_empty() {
                        None
                    } else {
                        Some(Ok(text))
                    }
                }
                Err(error) => Some(Err(error)),
            }
        })))
    }
}

/// Gemini-compatible content generation methods.
#[derive(Clone, Debug)]
pub struct GeminiService {
    client: Client,
}

impl GeminiService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Calls the Gemini-compatible non-streaming endpoint.
    pub async fn generate_content(&self, model: &str, body: ChatRequest) -> Result<ChatResponse> {
        let path = format!(
            "/api/v1beta/models/{}:generateContent",
            encode_model_path(model)
        );
        self.client
            .request_value(Method::POST, &path, None, Some(&body))
            .await
    }

    /// Streams raw Gemini-compatible server-sent events.
    pub async fn stream_generate_content(
        &self,
        model: &str,
        body: ChatRequest,
    ) -> Result<EventStream> {
        let path = format!(
            "/api/v1beta/models/{}:streamGenerateContent",
            encode_model_path(model)
        );
        let bytes = self
            .client
            .stream_json(Method::POST, &path, Some(&body))
            .await?;
        Ok(events_from_bytes(bytes))
    }

    /// Streams extracted Gemini-compatible text chunks.
    pub async fn stream_text(&self, model: &str, body: ChatRequest) -> Result<TextStream> {
        let stream = self.stream_generate_content(model, body).await?;
        Ok(Box::pin(stream.filter_map(|event| async move {
            match event {
                Ok(event) => {
                    let text = text_from_event(&event, StreamProtocol::Gemini);
                    if text.is_empty() {
                        None
                    } else {
                        Some(Ok(text))
                    }
                }
                Err(error) => Some(Err(error)),
            }
        })))
    }
}
