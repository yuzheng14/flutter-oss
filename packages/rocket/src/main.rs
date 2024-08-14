use std::ops::Deref;

use minio::s3::{
    args::{BucketExistsArgs, MakeBucketArgs, ObjectConditionalReadArgs, PutObjectApiArgs},
    client::Client,
    creds::StaticProvider,
    error::ErrorResponse,
    http::BaseUrl,
    response,
    types::{S3Api, ToStream},
};
use responder::{InternalServerError, InternalServerErrorResponder};
use rocket::{
    fairing::AdHoc,
    form::Form,
    futures::StreamExt,
    get,
    http::Status,
    launch, put, routes,
    serde::json::Json,
    tokio::{fs::File, io::AsyncReadExt},
    State,
};
use serde::{Deserialize, Serialize};
use types::{Bucket, ListEntry, MinioError, UploadObjectForm};

mod responder;
mod types;

struct AppState {
    minio_client: Client,
}

/// ensure the bucket exists, if not create it
async fn ensure_bucket_exist(client: &Client, bucket_name: &str) -> Result<(), MinioError> {
    let exits = client
        .bucket_exists(&BucketExistsArgs::new(bucket_name)?)
        .await?;

    if !exits {
        client
            .make_bucket(&MakeBucketArgs::new(bucket_name)?)
            .await?;
    }

    Ok(())
}

#[get("/bucket")]
async fn bucket(
    state: &State<AppState>,
) -> Result<Json<Vec<Bucket>>, InternalServerErrorResponder> {
    let buckets = state.minio_client.list_buckets().send().await?.buckets;

    Ok(Json(buckets.into_iter().map(|b| b.into()).collect()))
}

#[get("/object")]
async fn object(
    state: &State<AppState>,
    config: &State<AppConfig>,
) -> Result<Json<Vec<ListEntry>>, InternalServerErrorResponder> {
    ensure_bucket_exist(&state.minio_client, &config.bucket_name).await?;

    let mut list_objects = state
        .minio_client
        .list_objects(&config.bucket_name)
        .to_stream()
        .await
        .collect::<Vec<Result<response::ListObjectsResponse, MinioError>>>()
        .await;

    let bucket = list_objects
        .pop()
        .ok_or(format!("list_objects is empty"))??;

    if bucket.name != config.bucket_name {
        Err(InternalServerError::new(
            "Bucket not found.".to_string(),
            Some(format!("{:#?}", bucket)),
        ))?;
    }

    Ok(Json(
        bucket.contents.into_iter().map(|o| o.into()).collect(),
    ))
}

#[put("/object/<object_name>", data = "<form>")]
async fn upload_file(
    state: &State<AppState>,
    config: &State<AppConfig>,
    object_name: &str,
    form: Form<UploadObjectForm<'_>>,
) -> Result<Status, InternalServerErrorResponder> {
    ensure_bucket_exist(&state.minio_client, &config.bucket_name).await?;

    // if object exists, return 204, else 201
    let stat = state
        .minio_client
        .stat_object(&ObjectConditionalReadArgs::new(
            &config.bucket_name,
            object_name,
        )?)
        .await;
    let status = match stat {
        Ok(_) => Status::NoContent,
        Err(MinioError::S3Error(ErrorResponse { code, .. })) if code == "NoSuchKey" => {
            Status::Created
        }
        Err(e) => return Err(e.into()),
    };

    // read file content
    let path = form
        .file
        .path()
        .map(|path| path.to_str())
        .flatten()
        .ok_or(InternalServerError::new(
            "File doesn't exist.".to_string(),
            None,
        ))?
        .to_string();
    let mut data = Vec::new();

    File::open(&path).await?.read_to_end(&mut data).await?;

    // upload
    state
        .minio_client
        .put_object_api(&PutObjectApiArgs::new(
            &config.bucket_name,
            object_name,
            &data,
        )?)
        .await?;

    Ok(status)
}

#[get("/config")]
async fn config(state: &State<AppConfig>) -> Json<AppConfig> {
    Json(state.deref().clone())
}

#[derive(Deserialize, Serialize, Debug, Clone)]
struct AppConfig {
    bucket_name: String,
    minio_url: String,
    minio_access_key: String,
    minio_secret_key: String,
}

#[launch]
fn rocket() -> _ {
    rocket::build()
        .mount("/", routes![bucket, object, config, upload_file])
        .attach(AdHoc::config::<AppConfig>())
        .attach(AdHoc::try_on_ignite("minio_client", |rocket| async {
            let config = rocket.state::<AppConfig>().unwrap().to_owned();

            Ok(rocket.manage(AppState {
                minio_client: Client::new(
                    config.minio_url.parse::<BaseUrl>().unwrap(),
                    Some(Box::new(StaticProvider::new(
                        &config.minio_access_key,
                        &config.minio_secret_key,
                        None,
                    ))),
                    None,
                    None,
                )
                .unwrap(),
            }))
        }))
}
