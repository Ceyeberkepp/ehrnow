use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::get,Json,Router};
use chrono::{DateTime,Utc};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct ReportedAllergy {id:Uuid,patient_id:Uuid,substance_label:String,reaction_label:String,recorded_at:DateTime<Utc>}
#[derive(Deserialize)]
struct CreateAllergy {substance_label:String,reaction_label:String}
async fn list(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>)->Result<Json<Vec<ReportedAllergy>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let rows=sqlx::query_as::<_,ReportedAllergy>("SELECT id,patient_id,substance_label,reaction_label,recorded_at FROM reported_allergies WHERE tenant_id=$1 AND patient_id=$2 ORDER BY recorded_at DESC LIMIT 100").bind(tenant).bind(patient).fetch_all(&s.db).await.map_err(internal)?;Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>,Json(body):Json<CreateAllergy>)->Result<(StatusCode,Json<ReportedAllergy>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.substance_label.trim().is_empty()||body.substance_label.chars().count()>250||body.reaction_label.trim().is_empty()||body.reaction_label.chars().count()>500 {return Err(err(StatusCode::BAD_REQUEST,"invalid allergy record"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"));}
 let row=sqlx::query_as::<_,ReportedAllergy>("INSERT INTO reported_allergies(tenant_id,patient_id,substance_label,reaction_label) VALUES($1,$2,$3,$4) RETURNING id,patient_id,substance_label,reaction_label,recorded_at").bind(tenant).bind(patient).bind(body.substance_label.trim()).bind(body.reaction_label.trim()).fetch_one(&mut *tx).await.map_err(internal)?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'reported_allergy',$2,'reported_allergy.created',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/patients/{id}/reported-allergies",get(list).post(create))}
