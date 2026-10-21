import { useState, type FormEvent } from 'react';

type Patient={id:string;mrn:string;given_name:string;family_name:string};
type Encounter={id:string;reason:string;status:string;started_at:string};
type Note={id:string;author_label:string;content:string;created_at:string};
type Props={patients:Patient[];request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function EncounterWorkspace({patients,request}:Props){
 const [patientId,setPatientId]=useState('');const [reason,setReason]=useState('');
 const [encounters,setEncounters]=useState<Encounter[]>([]);const [selected,setSelected]=useState('');
 const [notes,setNotes]=useState<Note[]>([]);const [author,setAuthor]=useState('Fictional Clinician');
 const [content,setContent]=useState('');const [error,setError]=useState('');const [busy,setBusy]=useState(false);
 async function loadPatient(id:string){setPatientId(id);setSelected('');setNotes([]);setError('');try{setEncounters(id?await request('/api/v1/patients/'+id+'/encounters'):[])}catch(e){setError(String(e))}}
 async function open(id:string){setSelected(id);try{setNotes(await request('/api/v1/encounters/'+id+'/notes'))}catch(e){setError(String(e))}}
 async function create(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await request('/api/v1/encounters','POST',{patient_id:patientId,reason});setReason('');await loadPatient(patientId)}catch(e){setError(String(e))}finally{setBusy(false)}}
 async function add(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await request('/api/v1/encounters/'+selected+'/notes','POST',{author_label:author,content});setContent('');await open(selected)}catch(e){setError(String(e))}finally{setBusy(false)}}
 async function finish(){setBusy(true);setError('');try{await request('/api/v1/encounters/'+selected+'/finish','POST');await loadPatient(patientId)}catch(e){setError(String(e))}finally{setBusy(false)}}
 const current=encounters.find(e=>e.id===selected);
 return <section className="panel">
 <h2>Encounters and notes</h2><p>Developer-only synthetic data. These notes have no verified author identity or clinical signature.</p>
 <div className="form"><label>Fictional patient<select aria-label="Fictional patient" value={patientId} onChange={e=>void loadPatient(e.target.value)}><option value="">Choose patient</option>{patients.map(p=><option key={p.id} value={p.id}>{p.family_name}, {p.given_name} ({p.mrn})</option>)}</select></label></div>
 {patientId&&<><form className="form" onSubmit={create}><label>Encounter reason<input required maxLength={500} value={reason} onChange={e=>setReason(e.target.value)}/></label><div className="actions"><button type="submit" disabled={busy}>Create encounter</button></div></form>
 <h2 className="section-heading">Patient encounters</h2><div className="encounter-list">{encounters.map(enc=><button type="button" className={selected===enc.id?'encounter-choice chosen':'encounter-choice'} onClick={()=>void open(enc.id)} key={enc.id}>{enc.reason} · {enc.status} · {new Date(enc.started_at).toLocaleDateString()}</button>)}{encounters.length===0&&<p>No encounters yet.</p>}</div>
 {current&&<section className="panel nested"><h2>{current.reason}</h2><p>Status: {current.status}</p><h3>Development notes</h3>{notes.map(n=><article className="note" key={n.id}><strong>{n.author_label}</strong> <small>{new Date(n.created_at).toLocaleString()}</small><p>{n.content}</p></article>)}
 {current.status==='in-progress'&&<><form className="note-form" onSubmit={add}><label>Fictional author<input required maxLength={120} value={author} onChange={e=>setAuthor(e.target.value)}/></label><label>Note<textarea required maxLength={10000} rows={5} value={content} onChange={e=>setContent(e.target.value)}/></label><button disabled={busy} type="submit">Add note</button></form><button type="button" className="secondary" disabled={busy} onClick={()=>void finish()}>Finish sandbox encounter</button></>}</section>}</>}
 {error&&<p role="alert" className="error">{error}</p>}</section>;
}
