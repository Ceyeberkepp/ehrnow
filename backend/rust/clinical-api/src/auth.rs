use axum::{extract::State,http::{HeaderMap,StatusCode,header},routing::{get,post},Json,Router};
use serde::{Deserialize,Serialize};
use sqlx::Row;
use std::{collections::HashMap,sync::{Mutex,OnceLock},time::{Duration,Instant}};
use argon2::{Argon2,PasswordHash,PasswordHasher,PasswordVerifier,password_hash::SaltString};
use rand_core::OsRng;
use uuid::Uuid;
use crate::{AppState,ApiError,err,internal};
const SESSION_TTL:Duration=Duration::from_secs(8*3600);
static SESSIONS:OnceLock<Mutex<HashMap<String,Instant>>>=OnceLock::new();
fn sessions()->&'static Mutex<HashMap<String,Instant>> {SESSIONS.get_or_init(||Mutex::new(HashMap::new()))}
pub fn authenticated(headers:&HeaderMap)->bool{
 let value=headers.get(header::AUTHORIZATION).and_then(|x|x.to_str().ok()).and_then(|x|x.strip_prefix("Bearer "));
 let Some(value)=value else {return false};
 let Ok(mut sessions)=sessions().lock() else{return false};
 sessions.retain(|_,expiry|*expiry>Instant::now());
 sessions.get(value).is_some()
}
#[derive(Serialize)]
struct Status{setup_required:bool}
async fn status(State(s):State<AppState>)->Result<Json<Status>,ApiError>{
 let count:i64=sqlx::query_scalar("SELECT COUNT(*) FROM global_administrators").fetch_one(&s.db).await.map_err(internal)?;
 Ok(Json(Status{setup_required:count==0}))
}
#[derive(Deserialize)]
struct Credentials{username:String,password:String}
#[derive(Serialize)]
struct Session{access_token:String,username:String,role:&'static str,tenant_id:Uuid}
fn new_session(username:String)->Result<Json<Session>,ApiError>{
 let token=format!("{}{}{}",Uuid::new_v4().simple(),Uuid::new_v4().simple(),Uuid::new_v4().simple());
 sessions().lock().map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"session unavailable"))?.insert(token.clone(),Instant::now()+SESSION_TTL);
 Ok(Json(Session{access_token:token,username,role:"global_admin",tenant_id:Uuid::parse_str("00000000-0000-4000-8000-000000000001").expect("static tenant")}))
}
fn validate(body:&Credentials)->Result<(),ApiError>{
 if body.username.len()<3||body.username.len()>60||!body.username.chars().all(|c|c.is_ascii_alphanumeric()||matches!(c,'_'|'-'|'.')){return Err(err(StatusCode::BAD_REQUEST,"invalid username"))}
 if body.password.len()<14||body.password.len()>256{return Err(err(StatusCode::BAD_REQUEST,"password must contain 14-256 characters"))}
 Ok(())
}
async fn setup(State(s):State<AppState>,headers:HeaderMap,Json(body):Json<Credentials>)->Result<Json<Session>,ApiError>{
 let expected=std::env::var("EHR_SETUP_KEY").map_err(|_|err(StatusCode::SERVICE_UNAVAILABLE,"setup not configured"))?;
 let supplied=headers.get("x-ehr-setup-key").and_then(|v|v.to_str().ok()).unwrap_or("");
 if expected.len()<32 || supplied.len()!=expected.len() || !bool::from(subtle::ConstantTimeEq::ct_eq(supplied.as_bytes(),expected.as_bytes())) {return Err(err(StatusCode::FORBIDDEN,"invalid installation setup key"))}
 validate(&body)?;
 let mut tx=s.db.begin().await.map_err(internal)?;
 sqlx::query("SELECT pg_advisory_xact_lock(49318411)").execute(&mut *tx).await.map_err(internal)?;
 let count:i64=sqlx::query_scalar("SELECT COUNT(*) FROM global_administrators").fetch_one(&mut *tx).await.map_err(internal)?;
 if count>0{return Err(err(StatusCode::CONFLICT,"global administrator already configured"))}
 let salt=SaltString::generate(&mut OsRng);
 let hash=Argon2::default().hash_password(body.password.as_bytes(),&salt).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"password hashing failed"))?.to_string();
 sqlx::query("INSERT INTO global_administrators(username,password_hash) VALUES($1,$2)")
 .bind(&body.username).bind(hash).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;
 new_session(body.username)
}
async fn login(State(s):State<AppState>,Json(body):Json<Credentials>)->Result<Json<Session>,ApiError>{
 if body.username.len()>60||body.password.len()>256{return Err(err(StatusCode::UNAUTHORIZED,"invalid credentials"))}
 let row=sqlx::query("SELECT password_hash FROM global_administrators WHERE username=$1").bind(&body.username).fetch_optional(&s.db).await.map_err(internal)?;
 let Some(row)=row else {return Err(err(StatusCode::UNAUTHORIZED,"invalid credentials"))};
 let hash:String=row.try_get("password_hash").map_err(internal)?;
 let parsed=PasswordHash::new(&hash).map_err(|_|err(StatusCode::UNAUTHORIZED,"invalid credentials"))?;
 if Argon2::default().verify_password(body.password.as_bytes(),&parsed).is_err(){return Err(err(StatusCode::UNAUTHORIZED,"invalid credentials"))}
 new_session(body.username)
}
async fn logout(headers:HeaderMap)->StatusCode{
 if let Some(token)=headers.get(header::AUTHORIZATION).and_then(|x|x.to_str().ok()).and_then(|x|x.strip_prefix("Bearer ")){
  if let Ok(mut sessions)=sessions().lock(){sessions.remove(token);}
 }
 StatusCode::NO_CONTENT
}
pub fn routes()->Router<AppState>{Router::new().route("/auth/status",get(status)).route("/auth/setup",post(setup)).route("/auth/login",post(login)).route("/auth/logout",post(logout))}
