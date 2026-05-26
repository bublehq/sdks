use bytes::Bytes;
use futures_core::Stream;
use futures_util::StreamExt;
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use reqwest::{
    header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE},
    Method, Response, Url,
};
use serde::{de::DeserializeOwned, Serialize};
use serde_json::Value;

use crate::{
    client::Client,
    error::{ApiError, Error, Result},
};

impl Client {
    pub(crate) async fn request_json<T, B>(
        &self,
        method: Method,
        path: &str,
        query: Option<&[(&str, String)]>,
        body: Option<&B>,
    ) -> Result<T>
    where
        T: DeserializeOwned,
        B: Serialize + ?Sized,
    {
        let request = self.request_builder(method, path, query)?;
        let request = match body {
            Some(body) => request.header(CONTENT_TYPE, "application/json").json(body),
            None => request,
        };
        let response = request.send().await?;
        parse_json_response(response).await
    }

    pub(crate) async fn request_value<B>(
        &self,
        method: Method,
        path: &str,
        query: Option<&[(&str, String)]>,
        body: Option<&B>,
    ) -> Result<Value>
    where
        B: Serialize + ?Sized,
    {
        self.request_json(method, path, query, body).await
    }

    pub(crate) async fn send_multipart<T>(
        &self,
        path: &str,
        form: reqwest::multipart::Form,
    ) -> Result<T>
    where
        T: DeserializeOwned,
    {
        let response = self
            .request_builder(Method::POST, path, None)?
            .multipart(form)
            .send()
            .await?;
        parse_json_response(response).await
    }

    pub(crate) async fn stream_json<B>(
        &self,
        method: Method,
        path: &str,
        body: Option<&B>,
    ) -> Result<impl Stream<Item = Result<Bytes>> + Send + 'static>
    where
        B: Serialize + ?Sized,
    {
        let request = self
            .request_builder(method, path, None)?
            .header(ACCEPT, "text/event-stream");
        let request = match body {
            Some(body) => request.header(CONTENT_TYPE, "application/json").json(body),
            None => request,
        };
        let response = request.send().await?;
        if !response.status().is_success() {
            return Err(parse_api_error(response).await.into());
        }
        Ok(response
            .bytes_stream()
            .map(|chunk| chunk.map_err(Error::from)))
    }

    fn request_builder(
        &self,
        method: Method,
        path: &str,
        query: Option<&[(&str, String)]>,
    ) -> Result<reqwest::RequestBuilder> {
        let url = self.resolve_url(path, query)?;
        let mut request = self
            .inner
            .http
            .request(method, url)
            .header(AUTHORIZATION, format!("Bearer {}", self.inner.api_key))
            .header(ACCEPT, "application/json");
        for (name, value) in &self.inner.headers {
            request = request.header(name, value);
        }
        Ok(request)
    }

    fn resolve_url(&self, path: &str, query: Option<&[(&str, String)]>) -> Result<Url> {
        let mut url = self.inner.base_url.join(path)?;
        if let Some(query) = query {
            let mut pairs = url.query_pairs_mut();
            for (key, value) in query {
                if !value.is_empty() {
                    pairs.append_pair(key, value);
                }
            }
        }
        Ok(url)
    }
}

async fn parse_json_response<T>(response: Response) -> Result<T>
where
    T: DeserializeOwned,
{
    if !response.status().is_success() {
        return Err(parse_api_error(response).await.into());
    }
    Ok(response.json::<T>().await?)
}

async fn parse_api_error(response: Response) -> ApiError {
    let status = response.status();
    let body = response.text().await.unwrap_or_default();
    let mut message = body.clone();
    let mut code = None;
    let mut details = None;

    if !body.is_empty() {
        if let Ok(value) = serde_json::from_str::<Value>(&body) {
            if let Some(error) = value.get("error").and_then(Value::as_object) {
                if let Some(error_message) = error.get("message").and_then(Value::as_str) {
                    message = error_message.to_string();
                }
                code = error
                    .get("code")
                    .and_then(Value::as_str)
                    .map(str::to_string);
                details = error.get("details").cloned();
            }
        }
    }

    if message.is_empty() {
        message = status.to_string();
    }

    ApiError {
        status,
        code,
        message,
        details,
        body,
    }
}

pub(crate) fn encode_path_segment(value: &str) -> String {
    utf8_percent_encode(value, NON_ALPHANUMERIC).to_string()
}

pub(crate) fn encode_model_path(value: &str) -> String {
    value
        .split('/')
        .map(encode_path_segment)
        .collect::<Vec<_>>()
        .join("/")
}
