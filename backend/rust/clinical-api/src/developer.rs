use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::{get,post},Json,Router};
use serde::{Deserialize,Serialize};
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Module {key:String,label:String,enabled:bool,sort_order:i32}
#[derive(Serialize,sqlx::FromRow)]
struct Permission {key:String,module_key:String,label:String}
#[derive(Serialize,sqlx::FromRow)]
struct Role {id:Uuid,name:String,description:String}
#[derive(Deserialize)]
struct CreateRole {name:String,description:String}
#[derive(Deserialize)]
struct SetPermissions {permissions:Vec<String>}
#[derive(Deserialize)]
struct SetModule {enabled:bool}
async fn catalog(State(s):State<AppState>,headers:HeaderMap)->Result<Json<serde_json::Value>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let modules=sqlx::query_as::<_,Module>("SELECT key,label,enabled,sort_order FROM app_modules ORDER BY sort_order").fetch_all(&s.db).await.map_err(internal)?;
 let permissions=sqlx::query_as::<_,Permission>("SELECT key,module_key,label FROM app_permissions ORDER BY key").fetch_all(&s.db).await.map_err(internal)?;
 let roles=sqlx::query_as::<_,Role>("SELECT id,name,description FROM app_roles WHERE tenant_id=$1 ORDER BY name").bind(tenant).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(serde_json::json!({"modules":modules,"permissions":permissions,"roles":roles,"mode":"configuration-preview-only"})))
}
async fn create_role(State(s):State<AppState>,headers:HeaderMap,Json(body):Json<CreateRole>)->Result<(StatusCode,Json<Role>),ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if !(2..=80).contains(&body.name.trim().chars().count()) || body.description.chars().count()>500{return Err(err(StatusCode::BAD_REQUEST,"invalid role"));}
 let role=sqlx::query_as::<_,Role>("INSERT INTO app_roles(tenant_id,name,description) VALUES($1,$2,$3) RETURNING id,name,description")
 .bind(tenant).bind(body.name.trim()).bind(body.description.trim()).fetch_one(&s.db).await.map_err(|e|match &e {sqlx::Error::Database(d) if d.code().as_deref()==Some("23505")=>err(StatusCode::CONFLICT,"role already exists"),_=>internal(e)})?;
 Ok((StatusCode::CREATED,Json(role)))
}
async fn role_permissions(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Vec<String>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM app_roles WHERE tenant_id=$1 AND id=$2").bind(tenant).bind(id).fetch_optional(&s.db).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"role not found"));}
 let values=sqlx::query_scalar("SELECT permission_key FROM app_role_permissions WHERE tenant_id=$1 AND role_id=$2 ORDER BY permission_key").bind(tenant).bind(id).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(values))
}
async fn set_permissions(State(s):State<AppState>,headers:HeaderMap,Path(id):Path<Uuid>,Json(body):Json<SetPermissions>)->Result<Json<Vec<String>>,ApiError>{
 authorize(&headers,&s.token)?;let tenant=demo_tenant(&headers)?;
 if body.permissions.len()>100{return Err(err(StatusCode::BAD_REQUEST,"too many permissions"));}
 let mut tx=s.db.begin().await.map_err(internal)?;
 let exists:Option<Uuid>=sqlx::query_scalar("SELECT id FROM app_roles WHERE tenant_id=$1 AND id=$2 FOR UPDATE").bind(tenant).bind(id).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::NOT_FOUND,"role not found"));}
 let mut values=body.permissions;values.sort();values.dedup();
 for key in &values {
 let exists:Option<String>=sqlx::query_scalar("SELECT key FROM app_permissions WHERE key=$1").bind(key).fetch_optional(&mut *tx).await.map_err(internal)?;
 if exists.is_none(){return Err(err(StatusCode::BAD_REQUEST,"unknown permission"));}
 }
 sqlx::query("DELETE FROM app_role_permissions WHERE tenant_id=$1 AND role_id=$2").bind(tenant).bind(id).execute(&mut *tx).await.map_err(internal)?;
 for key in &values {sqlx::query("INSERT INTO app_role_permissions(tenant_id,role_id,permission_key) VALUES($1,$2,$3)").bind(tenant).bind(id).bind(key).execute(&mut *tx).await.map_err(internal)?;}
 tx.commit().await.map_err(internal)?;Ok(Json(values))
}
async fn set_module(State(s):State<AppState>,headers:HeaderMap,Path(key):Path<String>,Json(body):Json<SetModule>)->Result<Json<Module>,ApiError>{
 authorize(&headers,&s.token)?;demo_tenant(&headers)?;
 if key=="developer" && !body.enabled{return Err(err(StatusCode::BAD_REQUEST,"developer console cannot be disabled in sandbox"));}
 let module=sqlx::query_as::<_,Module>("UPDATE app_modules SET enabled=$1 WHERE key=$2 RETURNING key,label,enabled,sort_order").bind(body.enabled).bind(key).fetch_optional(&s.db).await.map_err(internal)?.ok_or_else(||err(StatusCode::NOT_FOUND,"module not found"))?;
 Ok(Json(module))
}
pub fn routes()->Router<AppState>{Router::new()
.route("/dev/admin/catalog",get(catalog))
.route("/dev/admin/roles",post(create_role))
.route("/dev/admin/roles/{id}/permissions",get(role_permissions).put(set_permissions))
.route("/dev/admin/modules/{key}",axum::routing::put(set_module))}
