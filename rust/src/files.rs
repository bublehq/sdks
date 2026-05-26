use std::path::{Path, PathBuf};

use bytes::Bytes;
use reqwest::multipart::{Form, Part};

use crate::{client::Client, error::Result, Envelope, UploadedFile};

/// File source for uploads to Buble.
#[derive(Clone, Debug)]
pub enum FileUpload {
    /// Upload bytes with a filename.
    Bytes {
        /// File bytes.
        bytes: Bytes,
        /// Filename.
        filename: String,
        /// MIME content type.
        content_type: Option<String>,
    },
    /// Upload a local file path.
    Path {
        /// Local path.
        path: PathBuf,
        /// Override filename.
        filename: Option<String>,
        /// Override MIME content type.
        content_type: Option<String>,
    },
}

impl FileUpload {
    /// Creates an upload source from bytes.
    pub fn from_bytes(bytes: impl Into<Bytes>, filename: impl Into<String>) -> Self {
        Self::Bytes {
            bytes: bytes.into(),
            filename: filename.into(),
            content_type: None,
        }
    }

    /// Creates an upload source from bytes with an explicit content type.
    pub fn from_bytes_with_content_type(
        bytes: impl Into<Bytes>,
        filename: impl Into<String>,
        content_type: impl Into<String>,
    ) -> Self {
        Self::Bytes {
            bytes: bytes.into(),
            filename: filename.into(),
            content_type: Some(content_type.into()),
        }
    }

    /// Creates an upload source from a local file path.
    pub fn from_path(path: impl Into<PathBuf>) -> Self {
        Self::Path {
            path: path.into(),
            filename: None,
            content_type: None,
        }
    }

    /// Overrides the uploaded filename.
    pub fn filename(mut self, filename: impl Into<String>) -> Self {
        match &mut self {
            Self::Bytes {
                filename: current, ..
            } => *current = filename.into(),
            Self::Path {
                filename: current, ..
            } => *current = Some(filename.into()),
        }
        self
    }

    /// Overrides the uploaded content type.
    pub fn content_type(mut self, content_type: impl Into<String>) -> Self {
        match &mut self {
            Self::Bytes {
                content_type: current,
                ..
            } => *current = Some(content_type.into()),
            Self::Path {
                content_type: current,
                ..
            } => *current = Some(content_type.into()),
        }
        self
    }

    async fn into_part(self) -> Result<Part> {
        match self {
            Self::Bytes {
                bytes,
                filename,
                content_type,
            } => {
                let content_type = content_type.unwrap_or_else(|| infer_content_type(&filename));
                Ok(Part::bytes(bytes.to_vec())
                    .file_name(filename)
                    .mime_str(&content_type)?)
            }
            Self::Path {
                path,
                filename,
                content_type,
            } => {
                let bytes = tokio::fs::read(&path).await?;
                let filename = filename.unwrap_or_else(|| file_name(&path));
                let content_type = content_type.unwrap_or_else(|| infer_content_type(&filename));
                Ok(Part::bytes(bytes)
                    .file_name(filename)
                    .mime_str(&content_type)?)
            }
        }
    }
}

/// Optional upload validation fields.
#[derive(Clone, Debug, Default)]
pub struct UploadOptions {
    /// File type: `image`, `video`, or `audio`.
    pub file_type: Option<String>,
    /// Model key for model-specific validation.
    pub model: Option<String>,
    /// Public mode for mode-specific validation.
    pub mode: Option<String>,
}

impl UploadOptions {
    /// Creates empty upload options.
    pub fn new() -> Self {
        Self::default()
    }

    /// Sets file type.
    pub fn file_type(mut self, file_type: impl Into<String>) -> Self {
        self.file_type = Some(file_type.into());
        self
    }

    /// Sets model.
    pub fn model(mut self, model: impl Into<String>) -> Self {
        self.model = Some(model.into());
        self
    }

    /// Sets mode.
    pub fn mode(mut self, mode: impl Into<String>) -> Self {
        self.mode = Some(mode.into());
        self
    }
}

/// Source media upload methods.
#[derive(Clone, Debug)]
pub struct FilesService {
    client: Client,
}

impl FilesService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Uploads an image, video, or audio file for use as generation input.
    pub async fn upload(
        &self,
        file: FileUpload,
        options: UploadOptions,
    ) -> Result<Envelope<UploadedFile>> {
        let mut form = Form::new().part("file", file.into_part().await?);
        if let Some(file_type) = options.file_type {
            form = form.text("file_type", file_type);
        }
        if let Some(model) = options.model {
            form = form.text("model", model);
        }
        if let Some(mode) = options.mode {
            form = form.text("mode", mode);
        }
        self.client.send_multipart("/api/v1/files", form).await
    }
}

fn file_name(path: &Path) -> String {
    path.file_name()
        .and_then(|value| value.to_str())
        .unwrap_or("file")
        .to_string()
}

fn infer_content_type(filename: &str) -> String {
    mime_guess::from_path(filename)
        .first_raw()
        .unwrap_or("application/octet-stream")
        .to_string()
}
