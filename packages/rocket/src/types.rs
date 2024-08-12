use std::collections::HashMap;

use minio::s3::types;
use rocket::{fs::TempFile, FromForm};
use serde::Serialize;

#[derive(Serialize)]
pub struct Bucket {
    name: String,
    creation_date: String,
}

impl From<types::Bucket> for Bucket {
    fn from(value: types::Bucket) -> Self {
        Self {
            name: value.name,
            creation_date: value.creation_date.to_string(),
        }
    }
}

#[derive(Serialize)]
pub struct Item {
    name: String,
    last_modified: Option<String>,
    etag: Option<String>, // except DeleteMarker
    owner_id: Option<String>,
    owner_name: Option<String>,
    size: Option<usize>, // except DeleteMarker
    storage_class: Option<String>,
    is_latest: bool,            // except ListObjects V1/V2
    version_id: Option<String>, // except ListObjects V1/V2
    user_metadata: Option<HashMap<String, String>>,
    is_prefix: bool,
    is_delete_marker: bool,
    encoding_type: Option<String>,
}

impl From<types::Item> for Item {
    fn from(value: types::Item) -> Self {
        Self {
            name: value.name,
            last_modified: value.last_modified.map(|v| v.to_string()),
            etag: value.etag,
            owner_id: value.owner_id,
            owner_name: value.owner_name,
            size: value.size,
            storage_class: value.storage_class,
            is_latest: value.is_latest,
            version_id: value.version_id,
            user_metadata: value.user_metadata,
            is_prefix: value.is_prefix,
            is_delete_marker: value.is_delete_marker,
            encoding_type: value.encoding_type,
        }
    }
}

#[derive(FromForm)]
pub struct UploadObjectForm<'r> {
    pub file: TempFile<'r>,
}

pub type MinioError = minio::s3::error::Error;
