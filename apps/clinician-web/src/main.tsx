import DeveloperCenter from './DeveloperCenter';
import ReportedAllergies from './ReportedAllergies';
import ProblemList from './ProblemList';
import Scheduling from './Scheduling';
import EncounterWorkspace from './EncounterWorkspace';
import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, Users, Shield, Search, Plus, HeartPulse, LayoutDashboard, Database } from 'lucide-react';
import './style.css';

type Patient = { id:string; mrn:string; given_name:string; family_name:string; birth_date:string };
const BASE=''; // same-origin Vite proxy keeps API off the LAN
function App(){
 const [token,setToken]=useState('');
 const [tenant,setTenant]=useState('');
 const [patients,setPatients]=useState<Patient[]>([]);
 const [view,setView]=useState('Patients');
 const [moduleCatalog,setModuleCatalog]=useState<{modules:{key:string;label:string;enabled:boolean}[]} | null>(null);
 const [search,setSearch]=useState('');
 const [error,setError]=useState('');
 const [busy,setBusy]=useState(false);
 const [form,setForm]=useState({mrn:'',given_name:'',family_name:'',birth_date:''});
 const connected=Boolean(tenant);
 async function call(path:string,method='GET',body?:unknown,tenantId=tenant){
  const response=await fetch(BASE+path,{method,headers:{Authorization:'Bearer '+token,'Content-Type':'application/json',...(tenantId?{'x-ehr-tenant-id':tenantId}:{})},...(body?{body:JSON.stringify(body)}:{})});
  if(!response.ok){const value=await response.json().catch(()=>({error:'Request failed'}));throw Error(value.error||'Request failed');}
  return response.json();
 }
 async function connect(){
  setBusy(true);setError('');
  try {const result=await call('/dev/bootstrap','POST');setTenant(result.tenant_id);
   const list=await call('/api/v1/patients','GET',undefined,result.tenant_id);setPatients(list);const catalog=await call('/dev/admin/catalog','GET',undefined,result.tenant_id);setModuleCatalog(catalog);
  } catch(e){setError(String(e));} finally{setBusy(false);}
 }
 async function refresh(){try{setPatients(await call('/api/v1/patients'));setError('');}catch(e){setError(String(e));}}
 async function save(e:React.FormEvent){e.preventDefault();setBusy(true);setError('');
  try{await call('/api/v1/patients','POST',form);setForm({mrn:'',given_name:'',family_name:'',birth_date:''});setView('Patients');await refresh();}
  catch(e){setError(String(e));}finally{setBusy(false);}
 }
 useEffect(()=>{if(!connected)return;const id=setInterval(()=>{void refresh()},30000);return()=>clearInterval(id)},[connected,token,tenant]);
 const filtered=patients.filter(p=>(p.given_name+' '+p.family_name+' '+p.mrn).toLowerCase().includes(search.toLowerCase()));
 return <div className="shell"><aside className="sidebar"><div className="brand"><HeartPulse size={27}/><strong>EHR<span>Now</span></strong></div><p className="side-label">CLINICAL WORKSPACE</p>
 {[['Overview',LayoutDashboard,'overview'],['Patients',Users,'patients'],['Encounters',Activity,'encounters'],['Problem List',Activity,'problems'],['Reported Allergies',Activity,'allergies'],['Scheduling',Activity,'scheduling'],['Infrastructure',Database,'infrastructure'],['Developer Center',Shield,'developer']].filter(([, ,key])=>moduleCatalog?.modules.find(m=>m.key===key)?.enabled).map(([name,Icon])=><button key={name as string} className={view===name?'nav active':'nav'} onClick={()=>setView(name as string)}><Icon size={18}/>{name as string}</button>)}
 <div className="sidebar-foot"><Shield size={17}/>Development environment<br/>Synthetic records only</div></aside>
 <main className="main"><header><div><small>EHRNow / {view}</small><h1>{view==='Developer Center'?'Developer Center':view==='Reported Allergies'?'Reported Allergies':view==='Problem List'?'Problem List':view==='Scheduling'?'Scheduling':view==='Encounters'?'Encounters & Notes':view==='Patients'?'Patient Registry':view==='Overview'?'Clinical Overview':view==='New Patient'?'Register Patient':'Platform Status'}</h1></div><div className="header-right"><span className="status"><span className="dot"/>{connected?'Connected to local API':'Not connected'}</span><span className="avatar">EN</span></div></header>
 <div className="warning"><Shield size={17}/> Developer preview — DO NOT enter real patient data or use for clinical care.</div>
 {!connected?<section className="panel connect"><Activity size={30}/><h2>Connect to local development API</h2><p>Enter the development token from your local .env file. This token stays in page memory and is not saved.</p><input type="password" autoComplete="off" aria-label="Development token" placeholder="Development token (32+ characters)" value={token} onChange={e=>setToken(e.target.value)}/><button disabled={busy||token.length<32} onClick={connect}>Connect</button></section>:
 view==='New Patient'?<section className="panel"><h2>New synthetic patient</h2><form onSubmit={save} className="form">
 {[['mrn','Medical record number'],['given_name','Given name'],['family_name','Family name'],['birth_date','Birth date']].map(([key,label])=><label key={key}>{label}<input required maxLength={120} type={key==='birth_date'?'date':'text'} value={form[key as keyof typeof form]} onChange={e=>setForm({...form,[key]:e.target.value})}/></label>)}
 <div className="actions"><button type="button" className="secondary" onClick={()=>setView('Patients')}>Cancel</button><button disabled={busy} type="submit">Create record</button></div></form></section>:
 view==='Developer Center'?<DeveloperCenter request={call} onCatalog={setModuleCatalog}/>:
 view==='Encounters'?<EncounterWorkspace patients={patients} request={call}/>:
 view==='Scheduling'?<Scheduling patients={patients} request={call}/>:
 view==='Problem List'?<ProblemList patients={patients} request={call}/>:
 view==='Reported Allergies'?<ReportedAllergies patients={patients} request={call}/>:
 view==='Patients'?<><div className="stats"><div className="stat"><small>Registered synthetic patients</small><strong>{patients.length}</strong><span>Local development database</span></div><div className="stat"><small>Connected tenant</small><strong>1</strong><span>Development only</span></div><div className="stat"><small>Clinical operations</small><strong>Not enabled</strong><span>Safety gates required</span></div></div><section className="panel"><div className="panel-top"><div><h2>Patient Directory</h2><p>Fictional registration records</p></div><button onClick={()=>setView('New Patient')}><Plus size={16}/>New Patient</button></div><div className="search"><Search size={18}/><input aria-label="Search patients" placeholder="Search by patient name or MRN" value={search} onChange={e=>setSearch(e.target.value)}/></div><div className="table-wrap"><table><thead><tr><th>Patient</th><th>MRN</th><th>Date of birth</th><th>Record ID</th></tr></thead><tbody>{filtered.map(p=><tr key={p.id}><td><b>{p.family_name}, {p.given_name}</b></td><td>{p.mrn}</td><td>{p.birth_date}</td><td className="mono">{p.id.slice(0,8)}…</td></tr>)}</tbody></table>{filtered.length===0&&<div className="empty">No matching fictional patient records yet.</div>}</div></section></>:
 <section className="panel"><h2>{view}</h2><p>{view==='Overview'?'Patient registry connected. Clinical chart, medication and ordering workflows require implementation and clinical verification.':'Rust clinical API and PostgreSQL registry connected. MongoDB, Neo4j, search and integrations are not yet clinically wired.'}</p></section>}
 {error&&<div role="alert" className="error">{error}</div>}
 </main></div>;
}
createRoot(document.getElementById('root')!).render(<React.StrictMode><App/></React.StrictMode>);
