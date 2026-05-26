use std::time::Duration;

use reqwest::StatusCode;
use serde_json::Value;
use thiserror::Error as ThisError;

use crate::{AppGenerationTask, GenerationTask};

/// SDK result type.
pub type Result<T> = std::result::Result<T, Error>;

/// Error type returned by the Buble Rust SDK.
#[derive(Debug, ThisError)]
pub enum Error {
    /// No API key was configured.
    #[error("missing Buble API key; pass Client::builder().api_key(...) or set BUBLE_API_KEY")]
    MissingApiKey,

    /// Client configuration is invalid.
    #[error("invalid Buble client configuration: {0}")]
    InvalidConfig(String),

    /// HTTP client error.
    #[error(transparent)]
    Http(#[from] reqwest::Error),

    /// JSON serialization or parsing error.
    #[error(transparent)]
    Json(#[from] serde_json::Error),

    /// URL parsing error.
    #[error(transparent)]
    Url(#[from] url::ParseError),

    /// Header value parsing error.
    #[error(transparent)]
    HeaderValue(#[from] reqwest::header::InvalidHeaderValue),

    /// I/O error, usually while reading an upload file.
    #[error(transparent)]
    Io(#[from] std::io::Error),

    /// Non-2xx response from the Buble API.
    #[error(transparent)]
    Api(#[from] ApiError),

    /// A known internal generation field was added to a public request.
    #[error("field {field:?} is an internal Buble field and is not supported by the public generation API")]
    UnsupportedGenerationField { field: String },

    /// A polling helper exceeded its timeout.
    #[error("{message}")]
    Timeout {
        /// Human-readable message.
        message: String,
        /// Timeout duration.
        timeout: Duration,
    },

    /// A media generation reached failed status.
    #[error("{message}")]
    GenerationFailed {
        /// Human-readable message.
        message: String,
        /// Final task snapshot.
        task: Box<GenerationTask>,
    },

    /// A media generation reached canceled status.
    #[error("{message}")]
    GenerationCanceled {
        /// Human-readable message.
        message: String,
        /// Final task snapshot.
        task: Box<GenerationTask>,
    },

    /// An app generation reached failed status.
    #[error("{message}")]
    AppGenerationFailed {
        /// Human-readable message.
        message: String,
        /// Final task snapshot.
        task: Box<AppGenerationTask>,
    },

    /// An app generation reached canceled status.
    #[error("{message}")]
    AppGenerationCanceled {
        /// Human-readable message.
        message: String,
        /// Final task snapshot.
        task: Box<AppGenerationTask>,
    },

    /// Streaming protocol parsing error.
    #[error("Buble stream error: {0}")]
    Stream(String),
}

/// API error returned for non-2xx Buble API responses.
#[derive(Debug, Clone)]
pub struct ApiError {
    /// HTTP status code.
    pub status: StatusCode,
    /// Buble API error code, when present.
    pub code: Option<String>,
    /// Human-readable error message.
    pub message: String,
    /// Structured error details, when present.
    pub details: Option<Value>,
    /// Raw response body.
    pub body: String,
}

impl std::fmt::Display for ApiError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match &self.code {
            Some(code) => write!(
                formatter,
                "Buble API error {} {}: {}",
                self.status.as_u16(),
                code,
                self.message
            ),
            None => write!(
                formatter,
                "Buble API error {}: {}",
                self.status.as_u16(),
                self.message
            ),
        }
    }
}

impl std::error::Error for ApiError {}
