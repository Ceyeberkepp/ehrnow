mod auth;
mod forms;
mod developer;
mod allergies;
mod problems;
mod scheduling;
mod encounters;
use axum::{extract::{Path, State}, http::{header, HeaderMap, StatusCode}, routing::{get, post}, Json, Router};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::{env, net::SocketAddr, sync::Arc};
use subtle::ConstantTimeEq;
use uuid::Uuid;

#[derive(Clone)]
struct AppState { db: PgPool, token: Arc<String> }
#[derive(Serialize, sqlx::FromRow)]
struct Patient { id: Uuid, tenant_id: Uuid, mrn: String, given_name: String, family_name: String, birth_date: NaiveDate }
#[derive(Deserialize)]
struct NewPatient { mrn: String, given_name: String, family_name: String, birth_date: NaiveDate }
#[derive(Serialize)]
struct ErrorMessage { error: &'static str }
type ApiError = (StatusCode, Json<ErrorMessage>);
fn err(status: StatusCode, message: &'static str) -> ApiError { (status, Json(ErrorMessage { error: message })) }
fn authorize(headers: &HeaderMap, token: &str) -> Result<(), ApiError> {
    let provided = headers.get(header::AUTHORIZATION).and_then(|x| x.to_str().ok()).and_then(|x| x.strip_prefix("Bearer "));
    let valid = provided.map(|x| x.len() == token.len() && bool::from(x.as_bytes().ct_eq(token.as_bytes()))).unwrap_or(false);
    if valid || auth::authenticated(headers) { Ok(()) } else { Err(err(StatusCode::UNAUTHORIZED, "unauthorized")) }
}
fn demo_tenant(headers: &HeaderMap) -> Result<Uuid, ApiError> {
    let id = headers.get("x-ehr-tenant-id").and_then(|v| v.to_str().ok()).ok_or_else(|| err(StatusCode::BAD_REQUEST, "tenant header required"))?;
    { let parsed = Uuid::parse_str(id).map_err(|_| err(StatusCode::BAD_REQUEST, "invalid tenant ID"))?; if parsed != Uuid::parse_str("00000000-0000-4000-8000-000000000001").expect("static UUID") { return Err(err(StatusCode::FORBIDDEN,"development tenant only")); } Ok(parsed) }
}
async fn health() -> &'static str { "ok" }
async fn bootstrap(State(s): State<AppState>, headers: HeaderMap) -> Result<Json<serde_json::Value>, ApiError> {
    authorize(&headers, &s.token)?;
    let id = Uuid::parse_str("00000000-0000-4000-8000-000000000001").expect("static UUID");
    let exists: Option<Uuid> = sqlx::query_scalar("SELECT id FROM tenants WHERE id = $1")
        .bind(id).fetch_optional(&s.db).await.map_err(internal)?;
    if exists.is_none() { return Err(err(StatusCode::SERVICE_UNAVAILABLE, "development tenant missing")); }
    Ok(Json(serde_json::json!({"tenant_id": id})))
}
fn internal(_: sqlx::Error) -> ApiError { err(StatusCode::INTERNAL_SERVER_ERROR, "database operation failed") }
async fn list_patients(State(s): State<AppState>, headers: HeaderMap) -> Result<Json<Vec<Patient>>, ApiError> {
    authorize(&headers, &s.token)?;
    let tenant = demo_tenant(&headers)?;
    let patients = sqlx::query_as::<_, Patient>("SELECT id, tenant_id, mrn, given_name, family_name, birth_date FROM patients WHERE tenant_id = $1 ORDER BY created_at DESC LIMIT 100")
        .bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
    Ok(Json(patients))
}
async fn get_patient(State(s): State<AppState>, headers: HeaderMap, Path(id): Path<Uuid>) -> Result<Json<Patient>, ApiError> {
    authorize(&headers, &s.token)?;
    let tenant = demo_tenant(&headers)?;
    sqlx::query_as::<_, Patient>("SELECT id, tenant_id, mrn, given_name, family_name, birth_date FROM patients WHERE tenant_id = $1 AND id = $2")
        .bind(tenant).bind(id).fetch_optional(&s.db).await.map_err(internal)?
        .map(Json).ok_or_else(|| err(StatusCode::NOT_FOUND, "patient not found"))
}
async fn create_patient(State(s): State<AppState>, headers: HeaderMap, Json(p): Json<NewPatient>) -> Result<(StatusCode, Json<Patient>), ApiError> {
    authorize(&headers, &s.token)?;
    let tenant = demo_tenant(&headers)?;
    if [&p.mrn, &p.given_name, &p.family_name].iter().any(|x| x.trim().is_empty() || x.len() > 120) {
        return Err(err(StatusCode::BAD_REQUEST, "invalid patient fields"));
    }
    let mut tx = s.db.begin().await.map_err(internal)?;
    let patient = sqlx::query_as::<_, Patient>(
        "INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date) VALUES($1,$2,$3,$4,$5) RETURNING id, tenant_id, mrn, given_name, family_name, birth_date")
        .bind(tenant).bind(p.mrn.trim()).bind(p.given_name.trim()).bind(p.family_name.trim()).bind(p.birth_date)
        .fetch_one(&mut *tx).await.map_err(|e| match &e { sqlx::Error::Database(d) if d.code().as_deref() == Some("23505") => err(StatusCode::CONFLICT, "MRN already exists"), _ => internal(e) })?;
    let payload = serde_json::to_value(&patient).map_err(|_| err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
    sqlx::query("INSERT INTO outbox_events(tenant_id, aggregate_type, aggregate_id, event_type, payload) VALUES($1,'patient',$2,'patient.created',$3)")
        .bind(tenant).bind(patient.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
    tx.commit().await.map_err(internal)?;
    Ok((StatusCode::CREATED, Json(patient)))
}
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    if env::var("EHR_DEV_MODE").as_deref() != Ok("1") { return Err("development mode required; production security is not implemented".into()); }
    let token = env::var("EHR_DEV_TOKEN")?;
    if token.len() < 32 || token.contains("replace-with") { return Err("configure a unique EHR_DEV_TOKEN of at least 32 characters".into()); }
    let db = PgPoolOptions::new().max_connections(5).connect(&env::var("DATABASE_URL")?).await?;
    sqlx::migrate!().run(&db).await?;
    let state = AppState { db, token: Arc::new(token) };
    let cors = tower_http::cors::CorsLayer::new()
        .allow_origin("http://127.0.0.1:5173".parse::<axum::http::HeaderValue>()?)
        .allow_methods([axum::http::Method::GET, axum::http::Method::POST, axum::http::Method::PUT])
        .allow_headers([header::AUTHORIZATION, header::CONTENT_TYPE, "x-ehr-tenant-id".parse()?]);
    let app = Router::new().route("/health", get(health))
        .route("/dev/bootstrap", post(bootstrap))
        .route("/api/v1/patients", get(list_patients).post(create_patient))
        .route("/api/v1/patients/{id}", get(get_patient))
        .merge(auth::routes())
        .merge(encounters::routes())
        .merge(scheduling::routes())
        .merge(problems::routes())
        .merge(allergies::routes())
        .merge(developer::routes())
        .merge(forms::routes())
        .layer(cors).with_state(state);
    let addr: SocketAddr = env::var("EHR_BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:8080".to_string()).parse()?;
    println!("EHRNow DEVELOPMENT API on {addr}; synthetic records only");
    axum::serve(tokio::net::TcpListener::bind(addr).await?, app).await?;
    Ok(())
}
