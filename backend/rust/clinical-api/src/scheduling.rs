use axum::{extract::State,http::{HeaderMap,StatusCode},routing::get,Json,Router};
use chrono::{DateTime,Utc};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Practitioner{id:Uuid,display_name:String}
#[derive(Serialize,sqlx::FromRow)]
struct Location{id:Uuid,display_name:String}
#[derive(Serialize,sqlx::FromRow)]
struct Appointment{id:Uuid,patient_id:Uuid,practitioner_id:Uuid,location_id:Uuid,starts_at:DateTime<Utc>,ends_at:DateTime<Utc>,status:String,reason:String}
#[derive(Deserialize)]
struct NewAppointment{patient_id:Uuid,practitioner_id:Uuid,location_id:Uuid,starts_at:DateTime<Utc>,ends_at:DateTime<Utc>,reason:String}
async fn resources(State(s):State<AppState>,headers:HeaderMap)->Result<Json<serde_json::Value>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let providers=sqlx::query_as::<_,Practitioner>("SELECT id,display_name FROM practitioners WHERE tenant_id=$1 AND active=true ORDER BY display_name LIMIT 100").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
 let locations=sqlx::query_as::<_,Location>("SELECT id,display_name FROM care_locations WHERE tenant_id=$1 AND active=true ORDER BY display_name LIMIT 100").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(serde_json::json!({"practitioners":providers,"locations":locations})))
}
async fn seed(State(s):State<AppState>,headers:HeaderMap)->Result<Json<serde_json::Value>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let mut tx=s.db.begin().await.map_err(internal)?;
 let practitioner:Uuid=sqlx::query_scalar("SELECT id FROM practitioners WHERE tenant_id=$1 ORDER BY created_at LIMIT 1").bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?.unwrap_or(Uuid::nil());
 let practitioner=if practitioner.is_nil(){sqlx::query_scalar("INSERT INTO practitioners(tenant_id,display_name) VALUES($1,'Fictional Provider') RETURNING id").bind(tenant).fetch_one(&mut *tx).await.map_err(internal)?}else{practitioner};
 let location:Uuid=sqlx::query_scalar("SELECT id FROM care_locations WHERE tenant_id=$1 LIMIT 1").bind(tenant).fetch_optional(&mut *tx).await.map_err(internal)?.unwrap_or(Uuid::nil());
 let location=if location.is_nil(){sqlx::query_scalar("INSERT INTO care_locations(tenant_id,display_name) VALUES($1,'Synthetic Exam Room') RETURNING id").bind(tenant).fetch_one(&mut *tx).await.map_err(internal)?}else{location};
 tx.commit().await.map_err(internal)?;
 Ok(Json(serde_json::json!({"practitioner_id":practitioner,"location_id":location})))
}
async fn list(State(s):State<AppState>,headers:HeaderMap)->Result<Json<Vec<Appointment>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let rows=sqlx::query_as::<_,Appointment>("SELECT id,patient_id,practitioner_id,location_id,starts_at,ends_at,status,reason FROM appointments WHERE tenant_id=$1 ORDER BY starts_at DESC LIMIT 100").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Json(a):Json<NewAppointment>)->Result<(StatusCode,Json<Appointment>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if a.ends_at<=a.starts_at || a.reason.trim().is_empty() || a.reason.len()>500{return Err(err(StatusCode::BAD_REQUEST,"invalid appointment"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let row=sqlx::query_as::<_,Appointment>("INSERT INTO appointments(tenant_id,patient_id,practitioner_id,location_id,starts_at,ends_at,reason) VALUES($1,$2,$3,$4,$5,$6,$7) RETURNING id,patient_id,practitioner_id,location_id,starts_at,ends_at,status,reason").bind(tenant).bind(a.patient_id).bind(a.practitioner_id).bind(a.location_id).bind(a.starts_at).bind(a.ends_at).bind(a.reason.trim()).fetch_one(&mut *tx).await.map_err(|e|match &e {sqlx::Error::Database(db) if db.code().as_deref()==Some("23P01")=>err(StatusCode::CONFLICT,"appointment time unavailable"),sqlx::Error::Database(db) if db.code().as_deref()==Some("23503")=>err(StatusCode::BAD_REQUEST,"unknown patient, provider or location"),_=>internal(e)})?;
 let payload=serde_json::to_value(&row).map_err(|_|err(StatusCode::INTERNAL_SERVER_ERROR,"serialization failed"))?;
 sqlx::query("INSERT INTO outbox_events(tenant_id,aggregate_type,aggregate_id,event_type,payload) VALUES($1,'appointment',$2,'appointment.created',$3)").bind(tenant).bind(row.id).bind(payload).execute(&mut *tx).await.map_err(internal)?;
 tx.commit().await.map_err(internal)?;Ok((StatusCode::CREATED,Json(row)))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/scheduling/resources",get(resources)).route("/dev/scheduling/seed",axum::routing::post(seed)).route("/api/v1/appointments",get(list).post(create))}
