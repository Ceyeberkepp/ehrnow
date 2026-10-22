use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::{get,post},Json,Router};
use chrono::{DateTime,Utc};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Medication {id:Uuid,patient_id:Uuid,medication_name:String,dose_text:String,status:String,noted_at:DateTime<Utc>,stopped_at:Option<DateTime<Utc>>}
#[derive(Deserialize)]
struct NewMedication {medication_name:String,dose_text:String}
async fn list(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>)->Result<Json<Vec<Medication>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"))}
 let rows=sqlx::query_as::<_,Medication>("SELECT id,patient_id,medication_name,dose_text,status,noted_at,stopped_at FROM patient_medication_history WHERE tenant_id=$1 AND patient_id=$2 ORDER BY noted_at DESC LIMIT 100").bind(tenant).bind(patient).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>,Json(body):Json<NewMedication>)->Result<(StatusCode,Json<Medication>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.medication_name.trim().is_empty()||body.medication_name.len()>250||body.dose_text.trim().is_empty()||body.dose_text.len()>250{return Err(err(StatusCode::BAD_REQUEST,"invalid medication history"))}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"))}
 let row=sqlx::query_as::<_,Medication>("INSERT INTO patient_medication_history(tenant_id,patient_id,medication_name,dose_text) VALUES($1,$2,$3,$4) RETURNING id,patient_id,medication_name,dose_text,status,noted_at,stopped_at").bind(tenant).bind(patient).bind(body.medication_name.trim()).bind(body.dose_text.trim()).fetch_one(&mut *tx).await.map_err(internal)?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'medication_history',$2,'medication_history.reported',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
async fn stop(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Medication>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let mut tx=s.db.begin().await.map_err(internal)?;
 let row=sqlx::query_as::<_,Medication>("UPDATE patient_medication_history SET status='stopped',stopped_at=now() WHERE id=$1 AND tenant_id=$2 AND status='reported' RETURNING id,patient_id,medication_name,dose_text,status,noted_at,stopped_at").bind(id).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?.ok_or_else(||err(StatusCode::CONFLICT,"record not active or missing"))?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'medication_history',$2,'medication_history.stopped',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok(Json(row))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/patients/{id}/medication-history",get(list).post(create)).route("/api/v1/medication-history/{id}/stop",post(stop))}
