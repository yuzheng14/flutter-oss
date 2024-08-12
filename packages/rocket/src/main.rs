use std::ops::Deref;

use minio::s3::{
    args::{
        BucketExistsArgs, ListBucketsArgs, ListObjectsV2Args, MakeBucketArgs,
        ObjectConditionalReadArgs, PutObjectArgs, UploadObjectArgs,
    },
    client::Client,
    creds::StaticProvider,
    http::BaseUrl,
};
use responder::{InternalServerError, InternalServerErrorResponder};
use rocket::{
    fairing::AdHoc,
    form::Form,
    get,
    http::Status,
    launch, put, routes,
    serde::json::Json,
    tokio::{fs::File, task::spawn_blocking},
    State,
};
use serde::{Deserialize, Serialize};
use types::{Bucket, Item, MinioError, UploadObjectForm};

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
    let buckets = state
        .minio_client
        .list_buckets(&ListBucketsArgs::new())
        .await?
        .buckets;

    Ok(Json(buckets.into_iter().map(|b| b.into()).collect()))
}

#[get("/object")]
async fn object(
    state: &State<AppState>,
    config: &State<AppConfig>,
) -> Result<Json<Vec<Item>>, InternalServerErrorResponder> {
    ensure_bucket_exist(&state.minio_client, &config.bucket_name).await?;

    let objects = state
        .minio_client
        .list_objects_v2(&ListObjectsV2Args::new(&config.bucket_name)?)
        .await?
        .contents;

    Ok(Json(objects.into_iter().map(|o| o.into()).collect()))
}

#[put("/object/<object_name>", data = "<form>")]
async fn upload_file(
    state: &State<AppState>,
    config: &State<AppConfig>,
    object_name: &str,
    form: Form<UploadObjectForm<'_>>,
) -> Result<Status, InternalServerErrorResponder> {
    ensure_bucket_exist(&state.minio_client, &config.bucket_name).await?;

    state
        .minio_client
        .stat_object(&ObjectConditionalReadArgs::new(
            &config.bucket_name,
            object_name,
        )?)
        .await?;

    let path = form
        .file
        .path()
        .map(|path| path.to_str())
        .flatten()
        .ok_or(InternalServerError::new(
            "File doesn't exist.".to_string(),
            format!(""),
        ))?
        .to_string();
    state
        .minio_client
        .upload_object(&UploadObjectArgs::new(
            &config.bucket_name,
            object_name,
            &path,
        )?)
        // .put_object(&mut PutObjectArgs::new(
        //     &config.bucket_name,
        //     object_name,
        //     &mut File::open(&path)
        //         .await
        //         .map_err(|err| Into::<MinioError>::into(err))?,
        //     None,
        //     None,
        // )?)
        .await?;
    // let handler = spawn_blocking(move || {
    //     let result = state.minio_client.upload_object(&UploadObjectArgs::new(
    //         &config.bucket_name,
    //         object_name,
    //         &path,
    //     )?);

    //     result
    // })
    // .await?
    // .await?;
    Ok(Status::Created)
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
        .mount("/", routes![bucket, object, config])
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
