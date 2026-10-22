use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::get,Json,Router};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Staff {id:Uuid,display_name:String,email:String,department:String,title:String,is_active:bool}
#[derive(Deserialize)]
struct NewStaff {display_name:String,email:String,department:String,title:String}
async fn list(State(s):State<AppState>,headers:HeaderMap)->Result<Json<Vec<Staff>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let rows=sqlx::query_as::<_,Staff>("SELECT id,display_name,email,department,title,is_active FROM staff_directory WHERE tenant_id=$1 ORDER BY display_name LIMIT 500").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Json(body):Json<NewStaff>)->Result<(StatusCode,Json<Staff>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.display_name.trim().chars().count()<2||body.display_name.len()>150||body.email.len()>250||!body.email.contains('@')||body.department.len()>120||body.title.len()>120{return Err(err(StatusCode::BAD_REQUEST,"invalid staff entry"))}
 let row=sqlx::query_as::<_,Staff>("INSERT INTO staff_directory(tenant_id,display_name,email,department,title) VALUES($1,$2,$3,$4,$5) RETURNING id,display_name,email,department,title,is_active").bind(tenant).bind(body.display_name.trim()).bind(body.email.trim().to_lowercase()).bind(body.department.trim()).bind(body.title.trim()).fetch_one(&s.db).await.map_err(|e|match &e {sqlx::Error::Database(d) if d.code().as_deref()==Some("23505")=>err(StatusCode::CONFLICT,"email already exists"),_=>internal(e)})?;
 Ok((StatusCode::CREATED,Json(row)))
}
async fn deactivate(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Staff>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let row=sqlx::query_as::<_,Staff>("UPDATE staff_directory SET is_active=false WHERE id=$1 AND tenant_id=$2 AND is_active=true RETURNING id,display_name,email,department,title,is_active").bind(id).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?.ok_or_else(||err(StatusCode::NOT_FOUND,"active staff entry not found"))?;
 Ok(Json(row))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/admin/staff",get(list).post(create)).route("/api/v1/admin/staff/{id}/deactivate",axum::routing::post(deactivate))}
