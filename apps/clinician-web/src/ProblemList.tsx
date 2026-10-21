import {useState,type FormEvent} from 'react';
type Patient={id:string;given_name:string;family_name:string;mrn:string};
type Problem={id:string;description:string;clinical_status:string;recorded_at:string};
type Props={patients:Patient[];request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function ProblemList({patients,request}:Props){
 const [patient,setPatient]=useState('');const [items,setItems]=useState<Problem[]>([]);
 const [description,setDescription]=useState('');const [busy,setBusy]=useState(false);const [error,setError]=useState('');
 async function load(id:string){setPatient(id);setError('');try{setItems(id?await request('/api/v1/patients/'+id+'/problems'):[])}catch(e){setError(String(e))}}
 async function add(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await request('/api/v1/patients/'+patient+'/problems','POST',{description});setDescription('');await load(patient)}catch(e){setError(String(e))}finally{setBusy(false)}}
 async function resolve(id:string){setBusy(true);setError('');try{await request('/api/v1/problems/'+id+'/resolve','POST');await load(patient)}catch(e){setError(String(e))}finally{setBusy(false)}}
 return <section className="panel"><h2>Problem List — Synthetic Data Only</h2><p>Development feature only. This does not provide coded diagnosis, decision support, or a clinically verified chart.</p>
 <div className="form"><label>Patient<select value={patient} onChange={e=>void load(e.target.value)}><option value="">Select fictional patient</option>{patients.map(p=><option key={p.id} value={p.id}>{p.family_name}, {p.given_name} — {p.mrn}</option>)}</select></label></div>
 {patient&&<><form className="form" onSubmit={add}><label>Problem description<input maxLength={500} required value={description} onChange={e=>setDescription(e.target.value)}/></label><div className="actions"><button type="submit" disabled={busy}>Add synthetic problem</button></div></form>
 <div className="table-wrap"><table><thead><tr><th>Problem</th><th>Status</th><th>Recorded</th><th>Action</th></tr></thead><tbody>{items.map(p=><tr key={p.id}><td>{p.description}</td><td>{p.clinical_status}</td><td>{new Date(p.recorded_at).toLocaleString()}</td><td>{p.clinical_status==='active'&&<button disabled={busy} className="secondary" onClick={()=>void resolve(p.id)}>Resolve</button>}</td></tr>)}</tbody></table>{!items.length&&<p>No synthetic problems recorded.</p>}</div></>}
 {error&&<p role="alert" className="error">{error}</p>}</section>
}
