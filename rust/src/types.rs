use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

/// Common response shape for Buble media, file, and app endpoints.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Envelope<T> {
    /// Response payload.
    pub data: T,
}

/// Lifecycle status of an asynchronous generation task.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum TaskStatus {
    /// Task has been accepted and is waiting to run.
    Pending,
    /// Provider is generating output.
    Processing,
    /// Generation completed successfully.
    Success,
    /// Generation failed.
    Failed,
    /// Generation was canceled.
    Canceled,
    /// Unknown status returned by the API.
    #[serde(other)]
    Unknown,
}

impl TaskStatus {
    /// Returns true when the task is in a terminal state.
    pub fn is_terminal(&self) -> bool {
        matches!(self, Self::Success | Self::Failed | Self::Canceled)
    }
}

/// API-ready media model returned by model discovery.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaModel {
    /// Stable model key.
    pub model: String,
    /// Human-readable name.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Media type, such as `image` or `video`.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub media_type: Option<String>,
    /// Public operation modes.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub operations: Vec<MediaModelOperation>,
    /// Additional model metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Public operation mode for a media model.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaModelOperation {
    /// Public mode key.
    pub mode: String,
    /// Optional operation description.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Input requirements.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub input: Option<Value>,
    /// Public mode parameters.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub parameters: Vec<MediaModelParameter>,
    /// Additional operation metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Request parameter accepted by a model mode.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaModelParameter {
    /// Parameter name to send at the generation request root.
    pub name: String,
    /// JSON value type.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub r#type: Option<String>,
    /// Display label.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    /// Default value.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub default: Option<Value>,
    /// Enum values.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub r#enum: Option<Vec<Value>>,
    /// Discrete values.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub values: Option<Vec<Value>>,
    /// Minimum value.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub min: Option<Value>,
    /// Maximum value.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max: Option<Value>,
    /// Step value.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub step: Option<Value>,
    /// Whether this parameter is required.
    #[serde(default)]
    pub required: bool,
    /// Additional parameter metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Uploaded source asset.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct UploadedFile {
    /// Object type.
    pub object: String,
    /// Storage provider.
    pub provider: String,
    /// Public URL to pass into generation inputs.
    pub url: String,
    /// Storage key.
    pub key: String,
    /// File type.
    pub file_type: String,
    /// MIME content type.
    pub content_type: String,
    /// File size in bytes.
    pub size: u64,
    /// Original filename.
    pub filename: String,
    /// Additional upload metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Generated image asset.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaResultImage {
    /// Image URL.
    pub url: String,
    /// Additional image metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Generated video asset.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaResultVideo {
    /// Video URL.
    pub url: String,
    /// Preview video URL.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub preview_url: Option<String>,
    /// Thumbnail URL.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub thumbnail_url: Option<String>,
    /// Video duration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub duration: Option<Value>,
    /// Additional video metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Generated audio asset.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MediaResultAudio {
    /// Audio URL.
    pub url: String,
    /// Cover image URL.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub image_url: Option<String>,
    /// Title.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    /// Audio duration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub duration: Option<Value>,
    /// Additional audio metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Generated media assets.
#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct GenerationResult {
    /// Generated images.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub images: Vec<MediaResultImage>,
    /// Generated videos.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub videos: Vec<MediaResultVideo>,
    /// Generated audio files.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub audios: Vec<MediaResultAudio>,
    /// Additional result metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Task-level generation error.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct GenerationTaskError {
    /// Error code.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    /// Error message.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
    /// Additional error metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Direct media generation task.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct GenerationTask {
    /// Task id.
    pub id: String,
    /// Task status.
    pub status: TaskStatus,
    /// Model key.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    /// Media type.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub media_type: Option<String>,
    /// Public mode.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
    /// Charged credits.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cost_credits: Option<u64>,
    /// Created timestamp.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub created_at: Option<String>,
    /// Updated timestamp.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<String>,
    /// Generation result.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub result: Option<GenerationResult>,
    /// Task error.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<GenerationTaskError>,
    /// Additional task metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Callable Buble app workflow.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PublicApp {
    /// App id.
    pub id: String,
    /// Flat input parameters.
    #[serde(default)]
    pub input_parameters: Vec<AppInputParameter>,
    /// Additional app metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// App input parameter.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AppInputParameter {
    /// Parameter name.
    pub name: String,
    /// JSON value type.
    pub r#type: String,
    /// Allowed values.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub values: Vec<Value>,
    /// Additional parameter metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// App generation task.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AppGenerationTask {
    /// Task id.
    pub id: String,
    /// Task status.
    pub status: TaskStatus,
    /// Generated media result.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub result: Option<GenerationResult>,
    /// Task error.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<GenerationTaskError>,
    /// Additional app task metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// Callable chat model.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ChatModel {
    /// Stable model id.
    pub id: String,
    /// Object type.
    pub object: String,
    /// Unix creation timestamp.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub created: Option<i64>,
    /// Provider display name.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub owned_by: Option<String>,
    /// Human-readable name.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Optional description.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Capability flags.
    #[serde(default, skip_serializing_if = "Map::is_empty")]
    pub capabilities: Map<String, Value>,
    /// Optional model tags.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,
    /// Additional model metadata.
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

/// OpenAI-style model list returned by chat model discovery.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ChatModelList {
    /// Object type.
    pub object: String,
    /// Chat models.
    pub data: Vec<ChatModel>,
}
