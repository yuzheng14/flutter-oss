use rocket::{
    serde::{json::Json, Serialize},
    Responder,
};

use crate::types::MinioError;

#[derive(Serialize)]
pub struct InternalServerError {
    message: String,
    details: Option<String>,
}

impl InternalServerError {
    pub fn new(message: String, details: Option<String>) -> Self {
        Self { message, details }
    }
}

#[derive(Responder)]
#[response(status = 500, content_type = "json")]
pub struct InternalServerErrorResponder {
    inner: Json<InternalServerError>,
}

impl InternalServerErrorResponder {
    pub fn new(error: InternalServerError) -> Self {
        Self { inner: Json(error) }
    }
}

impl From<InternalServerError> for InternalServerErrorResponder {
    fn from(err: InternalServerError) -> Self {
        InternalServerErrorResponder::new(err)
    }
}

impl From<MinioError> for InternalServerErrorResponder {
    fn from(err: MinioError) -> Self {
        InternalServerErrorResponder {
            inner: Json(InternalServerError::new(
                err.to_string(),
                Some(format!("{:#?}", err)),
            )),
        }
    }
}

impl From<std::io::Error> for InternalServerErrorResponder {
    fn from(err: std::io::Error) -> Self {
        InternalServerErrorResponder {
            inner: Json(InternalServerError::new(
                err.to_string(),
                Some(format!("{:#?}", err)),
            )),
        }
    }
}

impl From<rocket::tokio::task::JoinError> for InternalServerErrorResponder {
    fn from(err: rocket::tokio::task::JoinError) -> Self {
        InternalServerErrorResponder {
            inner: Json(InternalServerError::new(
                err.to_string(),
                Some(format!("{:#?}", err)),
            )),
        }
    }
}

impl From<String> for InternalServerErrorResponder {
    fn from(err: String) -> Self {
        InternalServerErrorResponder {
            inner: Json(InternalServerError::new(err, None)),
        }
    }
}
