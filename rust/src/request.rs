use serde::Serialize;
use serde_json::{Map, Value};

use crate::error::Result;

pub(crate) fn to_value<T: Serialize>(value: T) -> Result<Value> {
    Ok(serde_json::to_value(value)?)
}

pub(crate) fn insert_if_present<T: Serialize>(
    body: &mut Map<String, Value>,
    key: &str,
    value: Option<T>,
) -> Result<()> {
    if let Some(value) = value {
        body.insert(key.to_string(), to_value(value)?);
    }
    Ok(())
}

pub(crate) fn insert_non_empty_string(
    body: &mut Map<String, Value>,
    key: &str,
    value: &Option<String>,
) {
    if let Some(value) = value {
        if !value.is_empty() {
            body.insert(key.to_string(), Value::String(value.clone()));
        }
    }
}

pub(crate) fn insert_non_empty_strings(
    body: &mut Map<String, Value>,
    key: &str,
    values: &[String],
) {
    if !values.is_empty() {
        body.insert(
            key.to_string(),
            Value::Array(
                values
                    .iter()
                    .map(|value| Value::String(value.clone()))
                    .collect(),
            ),
        );
    }
}

pub(crate) fn set_stream(body: &mut Value, stream: bool) {
    match body {
        Value::Object(map) => {
            map.insert("stream".to_string(), Value::Bool(stream));
        }
        _ => {
            let mut map = Map::new();
            map.insert("stream".to_string(), Value::Bool(stream));
            *body = Value::Object(map);
        }
    }
}
