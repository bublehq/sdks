use std::pin::Pin;

use bytes::Bytes;
use futures_core::Stream;
use futures_util::StreamExt;
use serde_json::Value;

use crate::error::{Error, Result};

/// Stream of parsed server-sent events.
pub type EventStream = Pin<Box<dyn Stream<Item = Result<SseEvent>> + Send>>;

/// Stream of extracted text chunks.
pub type TextStream = Pin<Box<dyn Stream<Item = Result<String>> + Send>>;

/// Protocol shape used to extract text from SSE payloads.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StreamProtocol {
    /// OpenAI-compatible chat completion chunks.
    OpenAi,
    /// Anthropic-compatible messages events.
    Anthropic,
    /// Gemini-compatible content chunks.
    Gemini,
}

/// Parsed server-sent event.
#[derive(Debug, Clone, PartialEq)]
pub struct SseEvent {
    /// Optional event name.
    pub event: Option<String>,
    /// Raw data payload.
    pub data: String,
    /// Parsed JSON payload, when `data` is JSON.
    pub json: Option<Value>,
}

pub(crate) fn events_from_bytes<S>(stream: S) -> EventStream
where
    S: Stream<Item = Result<Bytes>> + Send + 'static,
{
    Box::pin(async_stream::try_stream! {
        let mut stream = Box::pin(stream);
        let mut parser = SseParser::default();

        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            let text = std::str::from_utf8(&chunk)
                .map_err(|error| Error::Stream(format!("invalid UTF-8 in SSE stream: {error}")))?;
            for event in parser.push(text)? {
                if event.data == "[DONE]" {
                    return;
                }
                yield event;
            }
        }

        for event in parser.finish()? {
            if event.data == "[DONE]" {
                return;
            }
            yield event;
        }
    })
}

#[derive(Debug, Default)]
struct SseParser {
    pending: String,
    event: Option<String>,
    data: Vec<String>,
}

impl SseParser {
    fn push(&mut self, chunk: &str) -> Result<Vec<SseEvent>> {
        self.pending.push_str(chunk);
        let mut output = Vec::new();

        while let Some(index) = self.pending.find('\n') {
            let mut line = self.pending[..index].to_string();
            self.pending.replace_range(..=index, "");
            if line.ends_with('\r') {
                line.pop();
            }
            if let Some(event) = self.push_line(&line)? {
                output.push(event);
            }
        }

        Ok(output)
    }

    fn finish(&mut self) -> Result<Vec<SseEvent>> {
        let mut output = Vec::new();
        if !self.pending.is_empty() {
            let line = std::mem::take(&mut self.pending);
            if let Some(event) = self.push_line(line.trim_end_matches('\r'))? {
                output.push(event);
            }
        }
        if let Some(event) = self.flush()? {
            output.push(event);
        }
        Ok(output)
    }

    fn push_line(&mut self, line: &str) -> Result<Option<SseEvent>> {
        if line.is_empty() {
            return self.flush();
        }
        if line.starts_with(':') {
            return Ok(None);
        }

        let (field, value) = line.split_once(':').map_or((line, ""), |(field, value)| {
            let value = value.strip_prefix(' ').unwrap_or(value);
            (field, value)
        });

        match field {
            "event" => self.event = Some(value.to_string()),
            "data" => self.data.push(value.to_string()),
            _ => {}
        }
        Ok(None)
    }

    fn flush(&mut self) -> Result<Option<SseEvent>> {
        if self.event.is_none() && self.data.is_empty() {
            return Ok(None);
        }

        let data = std::mem::take(&mut self.data).join("\n");
        let json = if data.is_empty() || data == "[DONE]" {
            None
        } else {
            Some(serde_json::from_str(&data)?)
        };
        Ok(Some(SseEvent {
            event: self.event.take(),
            data,
            json,
        }))
    }
}

pub(crate) fn text_from_event(event: &SseEvent, protocol: StreamProtocol) -> String {
    let Some(payload) = event.json.as_ref() else {
        return String::new();
    };

    match protocol {
        StreamProtocol::OpenAi => text_from_openai(payload),
        StreamProtocol::Anthropic => {
            if event.event.as_deref() != Some("content_block_delta") {
                return String::new();
            }
            text_from_anthropic(payload)
        }
        StreamProtocol::Gemini => text_from_gemini(payload),
    }
}

fn text_from_openai(payload: &Value) -> String {
    payload
        .get("choices")
        .and_then(Value::as_array)
        .and_then(|choices| choices.first())
        .and_then(|choice| choice.get("delta"))
        .and_then(|delta| delta.get("content"))
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

fn text_from_anthropic(payload: &Value) -> String {
    payload
        .get("delta")
        .and_then(|delta| delta.get("text"))
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

fn text_from_gemini(payload: &Value) -> String {
    let mut output = String::new();
    let Some(parts) = payload
        .get("candidates")
        .and_then(Value::as_array)
        .and_then(|candidates| candidates.first())
        .and_then(|candidate| candidate.get("content"))
        .and_then(|content| content.get("parts"))
        .and_then(Value::as_array)
    else {
        return output;
    };

    for part in parts {
        if let Some(text) = part.get("text").and_then(Value::as_str) {
            output.push_str(text);
        }
    }
    output
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_multiline_sse_event() {
        let mut parser = SseParser::default();
        let events = parser
            .push("event: content_block_delta\ndata: {\"delta\":{\"text\":\"Hi\"}}\n\n")
            .expect("parse event");
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].event.as_deref(), Some("content_block_delta"));
        assert_eq!(text_from_event(&events[0], StreamProtocol::Anthropic), "Hi");
    }
}
