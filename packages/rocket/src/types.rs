use std::collections::HashMap;

use minio::s3::{response, types};
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

#[derive(FromForm)]
pub struct UploadObjectForm<'r> {
    pub file: TempFile<'r>,
}

pub type MinioError = minio::s3::error::Error;

#[derive(Serialize)]
pub struct ListEntry {
    pub name: String,
    pub last_modified: Option<String>,
    pub etag: Option<String>, // except DeleteMarker
    pub owner_id: Option<String>,
    pub owner_name: Option<String>,
    pub size: Option<u64>, // except DeleteMarker
    pub storage_class: Option<String>,
    pub is_latest: bool,            // except ListObjects V1/V2
    pub version_id: Option<String>, // except ListObjects V1/V2
    pub user_metadata: Option<HashMap<String, String>>,
    pub user_tags: Option<HashMap<String, String>>,
    pub is_prefix: bool,
    pub is_delete_marker: bool,
    pub encoding_type: Option<String>,
}

impl From<types::ListEntry> for ListEntry {
    fn from(value: types::ListEntry) -> Self {
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
            user_tags: value.user_tags,
            is_prefix: value.is_prefix,
            is_delete_marker: value.is_delete_marker,
            encoding_type: value.encoding_type,
        }
    }
}

#[derive(Serialize)]
pub struct ListObjectsResponse {
    // pub headers: HeaderMap,
    pub name: String,
    pub encoding_type: Option<String>,
    pub prefix: Option<String>,
    pub delimiter: Option<String>,
    pub is_truncated: bool,
    pub max_keys: Option<u16>,
    pub contents: Vec<ListEntry>,

    // ListObjectsV1
    pub marker: Option<String>,
    pub next_marker: Option<String>,

    // ListObjectsV2
    pub key_count: Option<u16>,
    pub start_after: Option<String>,
    pub continuation_token: Option<String>,
    pub next_continuation_token: Option<String>,

    // ListObjectVersions
    pub key_marker: Option<String>,
    pub next_key_marker: Option<String>,
    pub version_id_marker: Option<String>,
    pub next_version_id_marker: Option<String>,
}

impl From<response::ListObjectsResponse> for ListObjectsResponse {
    fn from(value: response::ListObjectsResponse) -> Self {
        Self {
            name: value.name,
            encoding_type: value.encoding_type,
            prefix: value.prefix,
            delimiter: value.delimiter,
            is_truncated: value.is_truncated,
            max_keys: value.max_keys,
            contents: value.contents.into_iter().map(ListEntry::from).collect(),
            marker: value.marker,
            next_marker: value.next_marker,
            key_count: value.key_count,
            start_after: value.start_after,
            continuation_token: value.continuation_token,
            next_continuation_token: value.next_continuation_token,
            key_marker: value.key_marker,
            next_key_marker: value.next_key_marker,
            version_id_marker: value.version_id_marker,
            next_version_id_marker: value.next_version_id_marker,
        }
    }
}
