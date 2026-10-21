use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::{get,post},Json,Router};
use chrono::{DateTime,Utc};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Encounter {id:Uuid,tenant_id:Uuid,patient_id:Uuid,status:String,reason:String,started_at:DateTime<Utc>,finished_at:Option<DateTime<Utc>>}
#[derive(Deserialize)]
struct NewEncounter {patient_id:Uuid,reason:String}
#[derive(Serialize,sqlx::FromRow)]
struct Note {id:Uuid,tenant_id:Uuid,encounter_id:Uuid,author_label:String,content:String,created_at:DateTime<Utc>}
#[derive(Deserialize)]
struct NewNote {author_label:String,content:String}
fn validate(v:&str,max:usize)->bool{!v.trim().is_empty() && v.chars().count()<=max}
async fn list(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>)->Result<Json<Vec<Encounter>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE tenant_id=$1 AND id=$2").bind(tenant).bind(patient).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let rows=sqlx::query_as::<_,Encounter>("SELECT * FROM encounters WHERE tenant_id=$1 AND patient_id=$2 ORDER BY started_at DESC LIMIT 100").bind(tenant).bind(patient).fetch_all(&s.db).await.map_err(internal)?;Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Json(body):Json<NewEncounter>)->Result<(StatusCode,Json<Encounter>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if !validate(&body.reason,500){return Err(err(StatusCode::BAD_REQUEST,"invalid reason"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE tenant_id=$1 AND id=$2").bind(tenant).bind(body.patient_id).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let row=sqlx::query_as::<_,Encounter>("INSERT INTO encounters(tenant_id,patient_id,reason) VALUES($1,$2,$3) RETURNING *").bind(tenant).bind(body.patient_id).bind(body.reason.trim()).fetch_one(&mut *tx).await.map_err(internal)?;
 let value=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'encounter',$2,'encounter.created',$3)").bind(tenant).bind(row.id).bind(value).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
async fn notes(State(s):State<AppState>,headers:HeaderMap,Path(encounter):Path<Uuid>)->Result<Json<Vec<Note>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM encounters WHERE id=$1 AND tenant_id=$2").bind(encounter).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"encounter not found"));}
 let rows=sqlx::query_as::<_,Note>("SELECT * FROM clinical_notes WHERE tenant_id=$1 AND encounter_id=$2 ORDER BY created_at DESC LIMIT 100").bind(tenant).bind(encounter).fetch_all(&s.db).await.map_err(internal)?;Ok(Json(rows))
}
async fn add_note(State(s):State<AppState>,headers:HeaderMap,Path(encounter):Path<Uuid>,Json(body):Json<NewNote>)->Result<(StatusCode,Json<Note>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if !validate(&body.author_label,120)||!validate(&body.content,10000){return Err(err(StatusCode::BAD_REQUEST,"invalid note"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let status:Option<String>=sqlx::query_scalar("SELECT status FROM encounters WHERE id=$1 AND tenant_id=$2 FOR UPDATE").bind(encounter).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?;
 if status.as_deref()!=Some("in-progress"){return Err(err(StatusCode::CONFLICT,"encounter not active or does not exist"));}
 let row=sqlx::query_as::<_,Note>("INSERT INTO clinical_notes(tenant_id,encounter_id,author_label,content) VALUES($1,$2,$3,$4) RETURNING *").bind(tenant).bind(encounter).bind(body.author_label.trim()).bind(body.content.trim()).fetch_one(&mut *tx).await.map_err(internal)?;
 let value=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'note',$2,'note.created',$3)").bind(tenant).bind(row.id).bind(value).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
async fn finish(State(s):State<AppState>,headers:HeaderMap,Path(encounter):Path<Uuid>)->Result<Json<Encounter>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let mut tx=s.db.begin().await.map_err(internal)?;
 let row=sqlx::query_as::<_,Encounter>("UPDATE encounters SET status='finished',finished_at=now() WHERE id=$1 AND tenant_id=$2 AND status='in-progress' RETURNING *").bind(encounter).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?.ok_or_else(||err(StatusCode::CONFLICT,"encounter not active or does not exist"))?;
 let value=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'encounter',$2,'encounter.finished',$3)").bind(tenant).bind(row.id).bind(value).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok(Json(row))
}
pub fn routes()->Router<AppState>{Router::new()
 .route("/api/v1/patients/{id}/encounters",get(list))
 .route("/api/v1/encounters",post(create))
 .route("/api/v1/encounters/{id}/notes",get(notes).post(add_note))
 .route("/api/v1/encounters/{id}/finish",post(finish))}
