use axum::{extract::{Path,State},http::{HeaderMap,StatusCode},routing::{get,post},Json,Router};
use serde::{Deserialize,Serialize};
use serde_json::Value;
use uuid::Uuid;
use crate::{AppState,ApiError,authorize,demo_tenant,err,internal};
#[derive(Serialize,sqlx::FromRow)]
struct Template{id:Uuid,name:String,version:i32,status:String,fields:Value,source_form_id:Option<Uuid>}
#[derive(Deserialize)]
struct NewTemplate{name:String,fields:Value}
fn valid(fields:&Value)->bool{
 let Some(fs)=fields.as_array() else{return false};
 if fs.len()>100{return false;}
 let mut keys=std::collections::HashSet::new();
 fs.iter().all(|f|{
 let id=f["id"].as_str().unwrap_or("");
 let label=f["label"].as_str().unwrap_or("");
 let typ=f["type"].as_str().unwrap_or("");
 id.len()>=2&&id.len()<=64&&id.chars().all(|c|c.is_ascii_lowercase()||c.is_ascii_digit()||c=='_')&&keys.insert(id.to_owned())&&
 !label.trim().is_empty()&&label.len()<=160&&
 matches!(typ,"text"|"number"|"date"|"boolean"|"textarea")&&f["required"].is_boolean()
 })
}
async fn list(State(s):State<AppState>,h:HeaderMap)->Result<Json<Vec<Template>>,ApiError>{
 authorize(&h,&s.token)?;let t=demo_tenant(&h)?;
 let rows=sqlx::query_as::<_,Template>("SELECT id,name,version,status,fields,source_form_id FROM form_templates WHERE tenant_id=$1 ORDER BY created_at DESC LIMIT 100").bind(t).fetch_all(&s.db).await.map_err(internal)?;
 Ok(Json(rows))
}
async fn create(State(s):State<AppState>,h:HeaderMap,Json(b):Json<NewTemplate>)->Result<(StatusCode,Json<Template>),ApiError>{
 authorize(&h,&s.token)?;let t=demo_tenant(&h)?;
 if b.name.trim().len()<2||b.name.len()>160||!valid(&b.fields){return Err(err(StatusCode::BAD_REQUEST,"invalid template"));}
 let row=sqlx::query_as::<_,Template>("INSERT INTO form_templates(tenant_id,name,fields) VALUES($1,$2,$3) RETURNING id,name,version,status,fields,source_form_id").bind(t).bind(b.name.trim()).bind(b.fields).fetch_one(&s.db).await.map_err(internal)?;
 Ok((StatusCode::CREATED,Json(row)))
}
async fn duplicate(State(s):State<AppState>,h:HeaderMap,Path(id):Path<Uuid>)->Result<(StatusCode,Json<Template>),ApiError>{
 authorize(&h,&s.token)?;let t=demo_tenant(&h)?;
 let row=sqlx::query_as::<_,Template>("INSERT INTO form_templates(tenant_id,name,fields,source_form_id) SELECT tenant_id,left(name||' (Copy)',160),fields,id FROM form_templates WHERE tenant_id=$1 AND id=$2 RETURNING id,name,version,status,fields,source_form_id").bind(t).bind(id).fetch_optional(&s.db).await.map_err(internal)?.ok_or_else(||err(StatusCode::NOT_FOUND,"form not found"))?;
 Ok((StatusCode::CREATED,Json(row)))
}
async fn mapping(State(s):State<AppState>,h:HeaderMap,Path(id):Path<Uuid>)->Result<Json<Value>,ApiError>{
 authorize(&h,&s.token)?;let t=demo_tenant(&h)?;
 let fields:Option<Value>=sqlx::query_scalar("SELECT fields FROM form_templates WHERE tenant_id=$1 AND id=$2").bind(t).bind(id).fetch_optional(&s.db).await.map_err(internal)?;
 let fs=fields.ok_or_else(||err(StatusCode::NOT_FOUND,"form not found"))?;
 let map=fs.as_array().map(|arr|arr.iter().map(|f|serde_json::json!({"field":f["id"],"storage":"form_entries.answers","key":f["id"]})).collect::<Vec<_>>()).unwrap_or_default();
 Ok(Json(serde_json::json!({"mapping":map,"status":"development-preview"})))
}
pub fn routes()->Router<AppState>{Router::new().route("/dev/forms",get(list).post(create)).route("/dev/forms/{id}/duplicate",post(duplicate)).route("/dev/forms/{id}/mapping",get(mapping))}
