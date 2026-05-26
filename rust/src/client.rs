use std::{env, sync::Arc, time::Duration};

use reqwest::{
    header::{HeaderMap, HeaderName, HeaderValue},
    Url,
};

use crate::{
    config::{DEFAULT_BASE_URL, DEFAULT_TIMEOUT},
    error::{Error, Result},
    AppsService, ChatService, FilesService, GenerationsService, MediaModelsService,
};

#[derive(Debug)]
pub(crate) struct ClientInner {
    pub(crate) api_key: String,
    pub(crate) base_url: Url,
    pub(crate) http: reqwest::Client,
    pub(crate) headers: HeaderMap,
}

/// Server-side client for the Buble public API.
#[derive(Clone, Debug)]
pub struct Client {
    pub(crate) inner: Arc<ClientInner>,
}

impl Client {
    /// Creates a client builder.
    pub fn builder() -> ClientBuilder {
        ClientBuilder::default()
    }

    /// Creates a client from `BUBLE_API_KEY` and optional `BUBLE_BASE_URL`.
    pub fn from_env() -> Result<Self> {
        Self::builder().build()
    }

    /// Returns the configured base URL.
    pub fn base_url(&self) -> &Url {
        &self.inner.base_url
    }

    /// Media model discovery methods.
    pub fn media_models(&self) -> MediaModelsService {
        MediaModelsService::new(self.clone())
    }

    /// Source media upload methods.
    pub fn files(&self) -> FilesService {
        FilesService::new(self.clone())
    }

    /// Direct media generation methods.
    pub fn generations(&self) -> GenerationsService {
        GenerationsService::new(self.clone())
    }

    /// Preconfigured app workflow methods.
    pub fn apps(&self) -> AppsService {
        AppsService::new(self.clone())
    }

    /// Chat model methods for OpenAI, Anthropic, and Gemini-compatible APIs.
    pub fn chat(&self) -> ChatService {
        ChatService::new(self.clone())
    }
}

/// Builder for [`Client`].
#[derive(Debug, Default)]
pub struct ClientBuilder {
    api_key: Option<String>,
    base_url: Option<String>,
    timeout: Option<Duration>,
    http: Option<reqwest::Client>,
    headers: HeaderMap,
}

impl ClientBuilder {
    /// Sets the Buble API key.
    pub fn api_key(mut self, api_key: impl Into<String>) -> Self {
        self.api_key = Some(api_key.into());
        self
    }

    /// Sets the Buble API base URL.
    pub fn base_url(mut self, base_url: impl Into<String>) -> Self {
        self.base_url = Some(base_url.into());
        self
    }

    /// Sets the request timeout used by the default HTTP client.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }

    /// Uses an externally configured reqwest client.
    pub fn http_client(mut self, http: reqwest::Client) -> Self {
        self.http = Some(http);
        self
    }

    /// Adds a default header to every request.
    pub fn header(mut self, name: HeaderName, value: HeaderValue) -> Self {
        self.headers.insert(name, value);
        self
    }

    /// Adds a default header to every request from string values.
    pub fn header_str(mut self, name: &str, value: &str) -> Result<Self> {
        let name = HeaderName::from_bytes(name.as_bytes()).map_err(|error| {
            Error::InvalidConfig(format!("invalid header name {name:?}: {error}"))
        })?;
        let value = HeaderValue::from_str(value)?;
        self.headers.insert(name, value);
        Ok(self)
    }

    /// Builds the client.
    pub fn build(self) -> Result<Client> {
        let api_key = self
            .api_key
            .or_else(|| env::var("BUBLE_API_KEY").ok())
            .filter(|value| !value.trim().is_empty())
            .ok_or(Error::MissingApiKey)?;

        let base_url = self
            .base_url
            .or_else(|| env::var("BUBLE_BASE_URL").ok())
            .unwrap_or_else(|| DEFAULT_BASE_URL.to_string());
        let base_url = Url::parse(base_url.trim_end_matches('/'))?;

        let http = match self.http {
            Some(http) => http,
            None => reqwest::Client::builder()
                .timeout(self.timeout.unwrap_or(DEFAULT_TIMEOUT))
                .build()?,
        };

        Ok(Client {
            inner: Arc::new(ClientInner {
                api_key,
                base_url,
                http,
                headers: self.headers,
            }),
        })
    }
}
