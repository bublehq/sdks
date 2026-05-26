//! Server-side Rust SDK for the Buble public API.
//!
//! Buble is available at [Buble]. The [Buble API documentation] describes the
//! supported endpoints, request shapes, authentication model, and model-specific
//! parameters.
//!
//! The SDK supports media model discovery, file uploads, asynchronous image and
//! video generation, preconfigured app workflows, and chat model calls through
//! OpenAI, Anthropic Messages, and Gemini-compatible API formats.
//!
//! Use [`Client::from_env`] to construct a client from `BUBLE_API_KEY` and
//! optional `BUBLE_BASE_URL`, or [`Client::builder`] for explicit configuration.
//!
//! Generation requests use Buble's flat public API shape. Stable generation
//! fields are represented directly on [`CreateGenerationRequest`], and
//! model-specific parameters are passed through [`CreateGenerationRequest::param`]
//! so newly configured Buble models can be used without requiring an SDK release.
//!
//! API keys are server credentials. Do not expose them in browser or other
//! client-side code.
//!
//! [Buble]: https://buble.ai/
//! [Buble API documentation]: https://buble.ai/docs

mod apps;
mod chat;
mod client;
mod config;
mod error;
mod files;
mod generations;
mod http;
mod media_models;
mod request;
mod streaming;
mod types;

pub use apps::{AppGenerationsService, AppsService, ListAppsParams};
pub use chat::{
    ChatCompletionsService, ChatModelsService, ChatRequest, ChatResponse, ChatService,
    GeminiService, MessagesService,
};
pub use client::{Client, ClientBuilder};
pub use config::{DEFAULT_BASE_URL, DEFAULT_TIMEOUT};
pub use error::{ApiError, Error, Result};
pub use files::{FileUpload, FilesService, UploadOptions};
pub use generations::{CreateGenerationRequest, GenerationsService, WaitOptions};
pub use media_models::MediaModelsService;
pub use streaming::{EventStream, SseEvent, StreamProtocol, TextStream};
pub use types::*;
