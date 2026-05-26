use std::time::Instant;

use reqwest::Method;
use serde_json::{Map, Value};
use tokio::time::sleep;

use crate::{
    client::Client,
    error::{Error, Result},
    generations::WaitOptions,
    http::encode_path_segment,
    AppGenerationTask, Envelope, PublicApp, TaskStatus,
};

/// Query parameters for app listing.
#[derive(Debug, Clone, Default)]
pub struct ListAppsParams {
    /// Page number. Defaults to the API default.
    pub page: Option<u32>,
    /// Page size. Defaults to the API default.
    pub limit: Option<u32>,
}

impl ListAppsParams {
    /// Creates empty list params.
    pub fn new() -> Self {
        Self::default()
    }

    /// Sets page.
    pub fn page(mut self, page: u32) -> Self {
        self.page = Some(page);
        self
    }

    /// Sets limit.
    pub fn limit(mut self, limit: u32) -> Self {
        self.limit = Some(limit);
        self
    }

    fn query(&self) -> Vec<(&str, String)> {
        let mut query = Vec::new();
        if let Some(page) = self.page {
            query.push(("page", page.to_string()));
        }
        if let Some(limit) = self.limit {
            query.push(("limit", limit.to_string()));
        }
        query
    }
}

/// Preconfigured app workflow methods.
#[derive(Clone, Debug)]
pub struct AppsService {
    client: Client,
}

impl AppsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// App generation methods.
    pub fn generations(&self) -> AppGenerationsService {
        AppGenerationsService::new(self.client.clone())
    }

    /// Lists callable app workflows.
    pub async fn list(&self, params: ListAppsParams) -> Result<Envelope<Vec<PublicApp>>> {
        let query = params.query();
        let query = if query.is_empty() {
            None
        } else {
            Some(query.as_slice())
        };
        self.client
            .request_json::<Envelope<Vec<PublicApp>>, ()>(Method::GET, "/api/v1/apps", query, None)
            .await
    }

    /// Retrieves one callable app workflow.
    pub async fn retrieve(&self, app_id: &str) -> Result<Envelope<PublicApp>> {
        let path = format!("/api/v1/apps/{}", encode_path_segment(app_id));
        self.client
            .request_json::<Envelope<PublicApp>, ()>(Method::GET, &path, None, None)
            .await
    }
}

/// App generation task methods.
#[derive(Clone, Debug)]
pub struct AppGenerationsService {
    client: Client,
}

impl AppGenerationsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Creates an asynchronous generation task from an app.
    pub async fn create(
        &self,
        app_id: &str,
        body: Map<String, Value>,
    ) -> Result<Envelope<AppGenerationTask>> {
        let path = format!("/api/v1/apps/{}/generations", encode_path_segment(app_id));
        self.client
            .request_json(Method::POST, &path, None, Some(&body))
            .await
    }

    /// Retrieves an app generation task.
    pub async fn retrieve(
        &self,
        app_id: &str,
        generation_id: &str,
    ) -> Result<Envelope<AppGenerationTask>> {
        let path = format!(
            "/api/v1/apps/{}/generations/{}",
            encode_path_segment(app_id),
            encode_path_segment(generation_id)
        );
        self.client
            .request_json::<Envelope<AppGenerationTask>, ()>(Method::GET, &path, None, None)
            .await
    }

    /// Polls an app generation task until it reaches a terminal status.
    pub async fn wait(
        &self,
        app_id: &str,
        generation_id: &str,
        options: WaitOptions,
    ) -> Result<Envelope<AppGenerationTask>> {
        let deadline = Instant::now() + options.timeout;
        loop {
            let envelope = self.retrieve(app_id, generation_id).await?;
            let task = &envelope.data;
            if task.status.is_terminal() {
                match task.status {
                    TaskStatus::Failed if options.throw_on_failed => {
                        let message = task
                            .error
                            .as_ref()
                            .and_then(|error| error.message.clone())
                            .unwrap_or_else(|| "Generation failed.".to_string());
                        return Err(Error::AppGenerationFailed {
                            message,
                            task: Box::new(envelope.data),
                        });
                    }
                    TaskStatus::Canceled if options.throw_on_canceled => {
                        return Err(Error::AppGenerationCanceled {
                            message: format!("App generation {generation_id} was canceled."),
                            task: Box::new(envelope.data),
                        });
                    }
                    _ => return Ok(envelope),
                }
            }

            if Instant::now() >= deadline {
                return Err(Error::Timeout {
                    message: format!(
                        "App generation {generation_id} did not finish within {:?}.",
                        options.timeout
                    ),
                    timeout: options.timeout,
                });
            }
            sleep(options.interval).await;
        }
    }
}
