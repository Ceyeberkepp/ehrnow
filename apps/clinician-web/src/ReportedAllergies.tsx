import {useState,type FormEvent} from 'react';
type Patient={id:string;mrn:string;given_name:string;family_name:string};
type Allergy={id:string;substance_label:string;reaction_label:string;recorded_at:string};
type Props={patients:Patient[];request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function ReportedAllergies({patients,request}:Props){
 const [patient,setPatient]=useState('');const [items,setItems]=useState<Allergy[]>([]);
 const [substance,setSubstance]=useState('');const [reaction,setReaction]=useState('');
 const [busy,setBusy]=useState(false);const [error,setError]=useState('');
 async function load(id:string){setPatient(id);setError('');try{setItems(id?await request('/api/v1/patients/'+id+'/reported-allergies'):[])}catch(e){setError(String(e))}}
 async function save(e:FormEvent){e.preventDefault();setBusy(true);setError('');try{await request('/api/v1/patients/'+patient+'/reported-allergies','POST',{substance_label:substance,reaction_label:reaction});setSubstance('');setReaction('');await load(patient)}catch(e){setError(String(e))}finally{setBusy(false)}}
 return <section className="panel"><h2>Reported Allergy History — Synthetic Data Only</h2><p>Unverified fictional reports. This screen does not check interactions, support prescribing, or provide clinical alerts.</p>
 <div className="form"><label>Patient<select value={patient} onChange={e=>void load(e.target.value)}><option value="">Choose fictional patient</option>{patients.map(p=><option key={p.id} value={p.id}>{p.family_name}, {p.given_name} — {p.mrn}</option>)}</select></label></div>
 {patient&&<><form className="form" onSubmit={save}><label>Reported substance<input required maxLength={250} value={substance} onChange={e=>setSubstance(e.target.value)}/></label><label>Reported reaction<input required maxLength={500} value={reaction} onChange={e=>setReaction(e.target.value)}/></label><div className="actions"><button disabled={busy} type="submit">Record fictional report</button></div></form>
 <div className="table-wrap"><table><thead><tr><th>Reported substance</th><th>Reported reaction</th><th>Recorded</th></tr></thead><tbody>{items.map(a=><tr key={a.id}><td>{a.substance_label}</td><td>{a.reaction_label}</td><td>{new Date(a.recorded_at).toLocaleString()}</td></tr>)}</tbody></table>{!items.length&&<p>No synthetic allergy reports.</p>}</div></>}
 {error&&<p role="alert" className="error">{error}</p>}</section>;
}
