use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::get,Json,Router};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Department{id:Uuid,name:String,description:String,active:bool}
#[derive(Deserialize)]
struct NewDepartment{name:String,description:String}
async fn list(State(s):State<AppState>,headers:HeaderMap)->Result<Json<Vec<Department>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let rows=sqlx::query_as::<_,Department>("SELECT id,name,description,active FROM organization_departments WHERE tenant_id=$1 ORDER BY name LIMIT 500").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,headers:HeaderMap,Json(body):Json<NewDepartment>)->Result<(StatusCode,Json<Department>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.name.trim().chars().count()<2||body.name.len()>120||body.description.len()>500{return Err(err(StatusCode::BAD_REQUEST,"invalid department"))}
 let row=sqlx::query_as::<_,Department>("INSERT INTO organization_departments(tenant_id,name,description) VALUES($1,$2,$3) RETURNING id,name,description,active").bind(tenant).bind(body.name.trim()).bind(body.description.trim()).fetch_one(&s.db).await.map_err(|e|match &e{sqlx::Error::Database(d) if d.code().as_deref()==Some("23505")=>err(StatusCode::CONFLICT,"department exists"),_=>internal(e)})?;
 Ok((StatusCode::CREATED,Json(row)))
}
async fn deactivate(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Department>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let row=sqlx::query_as::<_,Department>("UPDATE organization_departments SET active=false WHERE id=$1 AND tenant_id=$2 AND active=true RETURNING id,name,description,active").bind(id).bind(tenant).fetch_optional(&s.db).await.map_err(internal)?.ok_or_else(||err(StatusCode::NOT_FOUND,"active department not found"))?;
 Ok(Json(row))
}
pub fn routes()->Router<AppState>{Router::new().route("/api/v1/admin/departments",get(list).post(create)).route("/api/v1/admin/departments/{id}/deactivate",axum::routing::post(deactivate))}
