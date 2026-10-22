import FormStudio from './FormStudio';
import {useEffect,useState,type FormEvent} from 'react';
type Module={key:string;label:string;enabled:boolean;sort_order:number};
type Permission={key:string;module_key:string;label:string};
type Role={id:string;name:string;description:string};
type Catalog={modules:Module[];permissions:Permission[];roles:Role[]};
type Props={request:(path:string,method?:string,body?:unknown)=>Promise<any>;onCatalog:(c:Catalog)=>void};
export default function DeveloperCenter({request,onCatalog}:Props){
 const [catalog,setCatalog]=useState<Catalog>({modules:[],permissions:[],roles:[]});
 const [changes,setChanges]=useState<{id:number;entity_type:string;entity_id:string;operation:string;changed_at:string}[]>([]);
 const [name,setName]=useState('');const [description,setDescription]=useState('');
 const [selected,setSelected]=useState('');const [grants,setGrants]=useState<string[]>([]);
 const [error,setError]=useState('');const [status,setStatus]=useState('');
 async function refresh(){try{const x=await request('/dev/admin/catalog');setCatalog(x);onCatalog(x);setChanges(await request('/dev/admin/changes'));setError('')}catch(e){setError(String(e))}}
 useEffect(()=>{void refresh()},[]);
 async function create(e:FormEvent){e.preventDefault();try{const role:Role=await request('/dev/admin/roles','POST',{name,description});setName('');setDescription('');await refresh();setSelected(role.id);setGrants([]);setStatus('Role created (configuration only)')}catch(e){setError(String(e))}}
 async function choose(id:string){setSelected(id);setError('');try{setGrants(id?await request('/dev/admin/roles/'+id+'/permissions'):[])}catch(e){setError(String(e))}}
 async function save(){try{const next=await request('/dev/admin/roles/'+selected+'/permissions','PUT',{permissions:grants});setGrants(next);setStatus('Saved to PostgreSQL; not yet enforced as user permissions.')}catch(e){setError(String(e))}}
 async function toggle(m:Module){try{await request('/dev/admin/modules/'+m.key,'PUT',{enabled:!m.enabled});await refresh()}catch(e){setError(String(e))}}
 return <section className="panel"><h2>Developer Center & Subsystems</h2><div className="warning"><strong>Development-only configuration.</strong> Roles and visibility previews are not authenticated end-user permissions. Never use this configuration to protect patient information.</div>
 <h3>Subsystem catalog</h3><div className="admin-grid">{catalog.modules.map(m=><label className="admin-item" key={m.key}><span>{m.label}</span><input type="checkbox" checked={m.enabled} disabled={m.key==='developer' || (!m.enabled && !['overview','patients','encounters','problems','allergies','scheduling','infrastructure'].includes(m.key))} onChange={()=>void toggle(m)}/></label>)}</div>
 <h3>Role designer</h3><form className="form" onSubmit={create}><label>New role name<input required minLength={2} maxLength={80} value={name} onChange={e=>setName(e.target.value)}/></label><label>Description<input maxLength={500} value={description} onChange={e=>setDescription(e.target.value)}/></label><div className="actions"><button type="submit">Create role</button></div></form>
 <div className="form"><label>Edit role<select value={selected} onChange={e=>void choose(e.target.value)}><option value="">Choose a role</option>{catalog.roles.map(r=><option key={r.id} value={r.id}>{r.name}</option>)}</select></label></div>
 {selected&&<><h3>Permission matrix</h3><div className="admin-grid">{catalog.permissions.map(p=><label className="admin-item" key={p.key}><span>{p.label}<small> {p.key}</small></span><input type="checkbox" checked={grants.includes(p.key)} onChange={e=>setGrants(g=>e.target.checked?[...g,p.key]:g.filter(k=>k!==p.key))}/></label>)}</div><button onClick={()=>void save()}>Save role permissions</button></>}
 {status&&<p role="status">{status}</p>}{error&&<p role="alert" className="error">{error}</p>}
 <h3>Recent configuration changes</h3><div className="table-wrap"><table><thead><tr><th>Change</th><th>Subsystem</th><th>Recorded</th></tr></thead><tbody>{changes.map(ch=><tr key={ch.id}><td>{ch.operation}</td><td>{ch.entity_type}</td><td>{new Date(ch.changed_at).toLocaleString()}</td></tr>)}</tbody></table>{!changes.length&&<p>No configuration changes recorded.</p>}</div><FormStudio request={request}/><h3>Planned developer subsystems</h3><p>User-role assignment, tenant policy enforcement, menu/page designer, form designer, workflow designer, API integrations, audit viewer, system diagnostics, versioned publishing and rollback. These remain gated until real identity and authorization are implemented.</p></section>;
}
