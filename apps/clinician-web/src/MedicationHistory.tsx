import {useState,type FormEvent} from 'react';
type Patient={id:string;mrn:string;given_name:string;family_name:string};
type Item={id:string;medication_name:string;dose_text:string;status:string;noted_at:string;stopped_at:string|null};
type Props={patients:Patient[];request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function MedicationHistory({patients,request}:Props){
 const [patient,setPatient]=useState('');const [items,setItems]=useState<Item[]>([]);
 const [name,setName]=useState('');const [dose,setDose]=useState('');
 const [busy,setBusy]=useState(false);const [error,setError]=useState('');
 async function load(id:string){setPatient(id);setError('');try{setItems(id?await request('/api/v1/patients/'+id+'/medication-history'):[])}catch(e){setError(String(e))}}
 async function save(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await request('/api/v1/patients/'+patient+'/medication-history','POST',{medication_name:name,dose_text:dose});setName('');setDose('');await load(patient)}catch(e){setError(String(e))}finally{setBusy(false)}}
 async function stop(id:string){setBusy(true);setError('');try{await request('/api/v1/medication-history/'+id+'/stop','POST');await load(patient)}catch(e){setError(String(e))}finally{setBusy(false)}}
 return <section className="panel"><h2>Reported Medication History — Synthetic Data Only</h2><p>This is a fictional medication statement list. It does not prescribe, reconcile, check interactions, or issue pharmacy orders. “Stopped” only changes this test record.</p>
 <div className="form"><label>Patient<select value={patient} onChange={e=>void load(e.target.value)}><option value="">Choose fictional patient</option>{patients.map(p=><option key={p.id} value={p.id}>{p.family_name}, {p.given_name} — {p.mrn}</option>)}</select></label></div>
 {patient&&<><form className="form" onSubmit={save}><label>Reported medication name<input required maxLength={250} value={name} onChange={e=>setName(e.target.value)}/></label><label>Reported dose (free text)<input required maxLength={250} value={dose} onChange={e=>setDose(e.target.value)}/></label><div className="actions"><button disabled={busy} type="submit">Record fictional medication statement</button></div></form>
 <div className="table-wrap"><table><thead><tr><th>Medication</th><th>Reported dose</th><th>Status</th><th>Recorded</th><th>Action</th></tr></thead><tbody>{items.map(m=><tr key={m.id}><td>{m.medication_name}</td><td>{m.dose_text}</td><td>{m.status}</td><td>{new Date(m.noted_at).toLocaleString()}</td><td>{m.status==='reported'&&<button className="secondary" disabled={busy} onClick={()=>void stop(m.id)}>Mark stopped</button>}</td></tr>)}</tbody></table>{!items.length&&<p>No fictional medication statements.</p>}</div></>}
 {error&&<p role="alert" className="error">{error}</p>}</section>;
}
