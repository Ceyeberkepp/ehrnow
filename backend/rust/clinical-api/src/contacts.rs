use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::get,Json,Router};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Contact {id:Uuid,patient_id:Uuid,contact_name:String,relationship:String,phone:String}
#[derive(Deserialize)]
struct NewContact {contact_name:String,relationship:String,phone:String}
async fn list(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>)->Result<Json<Vec<Contact>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM patients WHERE id=$1 AND tenant_id=$2").bind(patient).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"patient not found"))}
 let rows=sqlx::query_as::<_,Contact>("SELECT id,patient_id,contact_name,relationship,phone FROM patient_contacts WHERE tenant_id=$1 AND patient_id=$2 ORDER BY created_at DESC LIMIT 100").bind(tenant).bind(patient).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Path(patient):Path<Uuid>,Json(body):Json<NewContact>)->Result<(StatusCode,Json<Contact>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.contact_name.trim().len()<2||body.contact_name.len()>150||body.relationship.trim().len()<2||body.relationship.len()>100||body.phone.trim().len()<3||body.phone.len()>50{return Err(err(StatusCode::BAD_REQUEST,"invalid contact fields"))}
 let row=sqlx::query_as::<_,Contact>("INSERT INTO patient_contacts(tenant_id,patient_id,contact_name,relationship,phone) SELECT tenant_id,id,$3,$4,$5 FROM patients WHERE tenant_id=$1 AND id=$2 RETURNING id,patient_id,contact_name,relationship,phone")
 .bind(tenant).bind(patient).bind(body.contact_name.trim()).bind(body.relationship.trim()).bind(body.phone.trim()).fetch_optional(&s.db).await.map_err(internal)?.ok_or_else(||err(StatusCode::NOT_FOUND,"patient not found"))?;
 Ok((StatusCode::CREATED,Json(row)))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/patients/{id}/contacts",get(list).post(create))}
