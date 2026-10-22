import {useEffect,useState,type FormEvent} from 'react';
type Department={id:string;name:string;description:string;active:boolean};
type Props={request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function Departments({request}:Props){
 const [items,setItems]=useState<Department[]>([]),[name,setName]=useState(''),[description,setDescription]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState('');
 async function refresh(){try{setItems(await request('/api/v1/admin/departments'));setError('')}catch(e){setError(String(e))}}
 useEffect(()=>{void refresh()},[]);
 async function save(e:FormEvent){e.preventDefault();setBusy(true);try{await request('/api/v1/admin/departments','POST',{name,description});setName('');setDescription('');await refresh()}catch(e){setError(String(e))}finally{setBusy(false)}}
 async function deactivate(id:string){setBusy(true);try{await request('/api/v1/admin/departments/'+id+'/deactivate','POST');await refresh()}catch(e){setError(String(e))}finally{setBusy(false)}}
 return <section className="panel"><h2>Departments — Development Administration</h2><p>Manage synthetic organizational department records. These records do not grant privileges or create enforced access boundaries.</p><form className="form" onSubmit={save}><label>Name<input required minLength={2} maxLength={120} value={name} onChange={e=>setName(e.target.value)}/></label><label>Description<input maxLength={500} value={description} onChange={e=>setDescription(e.target.value)}/></label><div className="actions"><button disabled={busy} type="submit">Create department</button></div></form><div className="table-wrap"><table><thead><tr><th>Department</th><th>Description</th><th>Status</th><th>Action</th></tr></thead><tbody>{items.map(d=><tr key={d.id}><td>{d.name}</td><td>{d.description}</td><td>{d.active?'Active':'Inactive'}</td><td>{d.active&&<button disabled={busy} className="secondary" onClick={()=>void deactivate(d.id)}>Deactivate</button>}</td></tr>)}</tbody></table>{!items.length&&<p>No departments created.</p>}</div>{error&&<p role="alert" className="error">{error}</p>}</section>;
}
