use reqwest::Method;

use crate::{client::Client, error::Result, Envelope, MediaModel};

/// Media model discovery methods.
#[derive(Clone, Debug)]
pub struct MediaModelsService {
    client: Client,
}

impl MediaModelsService {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    /// Lists API-ready media models.
    pub async fn list(&self, media_type: Option<&str>) -> Result<Envelope<Vec<MediaModel>>> {
        let query;
        let query_ref = if let Some(media_type) = media_type {
            query = [("media_type", media_type.to_string())];
            Some(query.as_slice())
        } else {
            None
        };
        self.client
            .request_json::<Envelope<Vec<MediaModel>>, ()>(
                Method::GET,
                "/api/v1/media_models",
                query_ref,
                None,
            )
            .await
    }
}
