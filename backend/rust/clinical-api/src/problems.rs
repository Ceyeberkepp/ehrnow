use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::{get,post},Json,Router};
use chrono::{DateTime,Utc};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Problem {id:Uuid,patient_id:Uuid,description:String,clinical_status:String,recorded_at:DateTime<Utc>,resolved_at:Option<DateTime<Utc>>}
#[derive(Deserialize)]
struct NewProblem {description:String}
async fn list(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>)->Result<Json<Vec<Problem>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let rows=sqlx::query_as::<_,Problem>("SELECT id,patient_id,description,clinical_status,recorded_at,resolved_at FROM patient_problems WHERE tenant_id=$1 AND patient_id=$2 ORDER BY recorded_at DESC LIMIT 100").bind(tenant).bind(patient).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>,Json(body):Json<NewProblem>)->Result<(StatusCode,Json<Problem>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.description.trim().is_empty()||body.description.chars().count()>500{return Err(err(StatusCode::BAD_REQUEST,"invalid description"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let row=sqlx::query_as::<_,Problem>("INSERT INTO patient_problems(tenant_id,patient_id,description) VALUES($1,$2,$3) RETURNING id,patient_id,description,clinical_status,recorded_at,resolved_at").bind(tenant).bind(patient).bind(body.description.trim()).fetch_one(&mut *tx).await.map_err(internal)?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'patient_problem',$2,'patient_problem.created',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
async fn resolve(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Problem>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let mut tx=s.db.begin().await.map_err(internal)?;
 let row=sqlx::query_as::<_,Problem>("UPDATE patient_problems SET clinical_status='resolved',resolved_at=now() WHERE id=$1 AND tenant_id=$2 AND clinical_status='active' RETURNING id,patient_id,description,clinical_status,recorded_at,resolved_at").bind(id).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?.ok_or_else(||err(StatusCode::CONFLICT,"problem not active or missing"))?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'patient_problem',$2,'patient_problem.resolved',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok(Json(row))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/patients/{id}/problems",get(list).post(create)).route("/api/v1/problems/{id}/resolve",post(resolve))}
