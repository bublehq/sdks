use std::time::{Duration, Instant};

use reqwest::Method;
use serde::Serialize;
use serde_json::{Map, Value};
use tokio::time::sleep;

use crate::{
    client::Client,
    error::{Error, Result},
    http::encode_path_segment,
    request::{insert_if_present, insert_non_empty_string, insert_non_empty_strings, to_value},
    Envelope, GenerationTask, TaskStatus,
};

const FORBIDDEN_GENERATION_FIELDS: &[&str] = &[
    "input",
    "options",
    "scene",
    "sub_mode_id",
    "subModeId",
    "provider",
    "mediaType",
    "media_type",
    "images",
    "image_input",
    "video_input",
    "audio_input",
];

/// Creates an asynchronous media generation task.
#[derive(Debug, Clone)]
pub struct CreateGenerationRequest {
    /// Model key from media model discovery.
    pub model: String,
    /// Public operation mode.
    pub mode: Option<String>,
    /// Text instruction.
    pub prompt: Option<String>,
    /// Reference/source image URLs.
    pub image_urls: Vec<String>,
    /// Start frame image URL.
    pub start_frame: Option<String>,
    /// End frame image URL.
    pub end_frame: Option<String>,
    /// Source video URLs.
    pub video_urls: Vec<String>,
    /// Source audio URLs.
    pub audio_urls: Vec<String>,
    /// Public visibility flag.
    pub is_public: Option<bool>,
    /// Copy protection flag.
    pub copy_protected: Option<bool>,
    /// Model-specific flat parameters.
    pub params: Map<String, Value>,
}

impl CreateGenerationRequest {
    /// Creates a request for a model.
    pub fn new(model: impl Into<String>) -> Self {
        Self {
            model: model.into(),
            mode: None,
            prompt: None,
            image_urls: Vec::new(),
            start_frame: None,
            end_frame: None,
            video_urls: Vec::new(),
            audio_urls: Vec::new(),
            is_public: None,
            copy_protected: None,
            params: Map::new(),
        }
    }

    /// Sets the public mode.
    pub fn mode(mut self, mode: impl Into<String>) -> Self {
        self.mode = Some(mode.into());
        self
    }

    /// Sets the text prompt.
    pub fn prompt(mut self, prompt: impl Into<String>) -> Self {
        self.prompt = Some(prompt.into());
        self
    }

    /// Sets image URLs.
    pub fn image_urls<I, S>(mut self, urls: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<String>,
    {
        self.image_urls = urls.into_iter().map(Into::into).collect();
        self
    }

    /// Sets the start frame URL.
    pub fn start_frame(mut self, url: impl Into<String>) -> Self {
        self.start_frame = Some(url.into());
        self
    }

    /// Sets the end frame URL.
    pub fn end_frame(mut self, url: impl Into<String>) -> Self {
        self.end_frame = Some(url.into());
        self
    }

    /// Sets video URLs.
    pub fn video_urls<I, S>(mut self, urls: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<String>,
    {
        self.video_urls = urls.into_iter().map(Into::into).collect();
        self
    }

    /// Sets audio URLs.
    pub fn audio_urls<I, S>(mut self, urls: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<String>,
    {
        self.audio_urls = urls.into_iter().map(Into::into).collect();
        self
    }

    /// Sets `is_public`.
    pub fn is_public(mut self, is_public: bool) -> Self {
        self.is_public = Some(is_public);
        self
    }

    /// Sets `copy_protected`.
    pub fn copy_protected(mut self, copy_protected: bool) -> Self {
        self.copy_protected = Some(copy_protected);
        self
    }

    /// Adds a model-specific parameter at the generation request root.
    pub fn param<T>(mut self, key: impl Into<String>, value: T) -> Result<Self>
    where
        T: Serialize,
    {
        let key = key.into();
        assert_supported_generation_field(&key)?;
        let value = to_value(value)?;
        if !value.is_null() {
            self.params.insert(key, value);
        }
        Ok(self)
    }

    pub(crate) fn into_body(self) -> Result<Map<String, Value>> {
        let mut body = Map::new();
        body.insert("model".to_string(), Value::String(self.model));
        insert_non_empty_string(&mut body, "mode", &self.mode);
        insert_non_empty_string(&mut body, "prompt", &self.prompt);
        insert_non_empty_strings(&mut body, "image_urls", &self.image_urls);
        insert_non_empty_string(&mut body, "start_frame", &self.start_frame);
        insert_non_empty_string(&mut body, "end_frame", &self.end_frame);
        insert_non_empty_strings(&mut body, "video_urls", &self.video_urls);
        insert_non_empty_strings(&mut body, "audio_urls", &self.audio_urls);
        insert_if_present(&mut body, "is_public", self.is_public)?;
        insert_if_present(&mut body, "copy_protected", self.copy_protected)?;

        for (key, value) in self.params {
            assert_supported_generation_field(&key)?;
            body.insert(key, value);
        }
        for key in body.keys() {
            assert_supported_generation_field(key)?;
        }
        Ok(body)
    }
}

/// Polling options for wait helpers.
#[derive(Debug, Clone)]
pub struct WaitOptions {
    /// Polling interval.
    pub interval: Duration,
    /// Overall polling timeout.
    pub timeout: Duration,
    /// Raise an error when the task reaches failed status.
    pub throw_on_failed: bool,
    /// Raise an error when the task reaches canceled status.
    pub throw_on_canceled: bool,
}

impl Default for WaitOptions {
    fn default() -> Self {
        Self {
            interval: Duration::from_secs(2),
            timeout: Duration::from_secs(600),
            throw_on_failed: true,
            throw_on_canceled: true,
        }
    }
}

impl WaitOptions {
    /// Creates default wait options.
    pub fn new() -> Self {
        Self::default()
    }

    /// Sets the polling interval.
    pub fn interval(mut self, interval: Duration) -> Self {
        self.interval = interval;
        self
    }

    /// Sets the polling timeout.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// Configures whether failed tasks produce errors.
    pub fn throw_on_failed(mut self, value: bool) -> Self {
        self.throw_on_failed = value;
        self
    }

    /// Configures whether canceled tasks produce errors.
    pub fn throw_on_canceled(mut self, value: bool) -> Self {
        self.throw_on_canceled = value;
        self
    }
}

/// Direct media generation methods.
#[derive(Clone, Debug)]
pub struct GenerationsService {
    client: Client,
}

impl GenerationsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Creates an asynchronous image, video, or audio generation task.
    pub async fn create(
        &self,
        request: CreateGenerationRequest,
    ) -> Result<Envelope<GenerationTask>> {
        let body = request.into_body()?;
        self.client
            .request_json(Method::POST, "/api/v1/generations", None, Some(&body))
            .await
    }

    /// Returns the current status and result for a media generation task.
    pub async fn retrieve(&self, id: &str) -> Result<Envelope<GenerationTask>> {
        let path = format!("/api/v1/generations/{}", encode_path_segment(id));
        self.client
            .request_json::<Envelope<GenerationTask>, ()>(Method::GET, &path, None, None)
            .await
    }

    /// Polls a media generation task until it reaches a terminal status.
    pub async fn wait(&self, id: &str, options: WaitOptions) -> Result<Envelope<GenerationTask>> {
        let deadline = Instant::now() + options.timeout;
        loop {
            let envelope = self.retrieve(id).await?;
            let task = &envelope.data;
            if task.status.is_terminal() {
                match task.status {
                    TaskStatus::Failed if options.throw_on_failed => {
                        let message = task
                            .error
                            .as_ref()
                            .and_then(|error| error.message.clone())
                            .unwrap_or_else(|| "Generation failed.".to_string());
                        return Err(Error::GenerationFailed {
                            message,
                            task: Box::new(envelope.data),
                        });
                    }
                    TaskStatus::Canceled if options.throw_on_canceled => {
                        return Err(Error::GenerationCanceled {
                            message: format!("Generation {id} was canceled."),
                            task: Box::new(envelope.data),
                        });
                    }
                    _ => return Ok(envelope),
                }
            }

            if Instant::now() >= deadline {
                return Err(Error::Timeout {
                    message: format!(
                        "Generation {id} did not finish within {:?}.",
                        options.timeout
                    ),
                    timeout: options.timeout,
                });
            }
            sleep(options.interval).await;
        }
    }
}

pub(crate) fn assert_supported_generation_field(field: &str) -> Result<()> {
    if FORBIDDEN_GENERATION_FIELDS.contains(&field) {
        return Err(Error::UnsupportedGenerationField {
            field: field.to_string(),
        });
    }
    Ok(())
}
