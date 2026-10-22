import {useEffect,useState,type FormEvent} from 'react';
type Field={id:string;label:string;type:'text'|'textarea'|'number'|'date'|'boolean';required:boolean};
type Template={id:string;name:string;version:number;fields:Field[];source_form_id:string|null};
type Props={request:(path:string,method?:string,body?:unknown)=>Promise<any>};
export default function FormStudio({request}:Props){
 const [forms,setForms]=useState<Template[]>([]),[name,setName]=useState('New Form');
 const [fields,setFields]=useState<Field[]>([]),[mapping,setMapping]=useState('');
 const [error,setError]=useState(''),[status,setStatus]=useState('');
 async function refresh(){try{setForms(await request('/dev/forms'));setError('')}catch(e){setError(String(e))}}
 useEffect(()=>{void refresh()},[]);
 function add(){setFields(x=>[...x,{id:'field_'+(x.length+1),label:'New field',type:'text',required:false}])}
 function edit(i:number,changes:Partial<Field>){setFields(xs=>xs.map((x,j)=>j===i?{...x,...changes}:x))}
 async function save(e:FormEvent){e.preventDefault();try{await request('/dev/forms','POST',{name,fields});setStatus('Draft form saved; not clinically approved.');await refresh()}catch(e){setError(String(e))}}
 async function duplicate(id:string){try{await request('/dev/forms/'+id+'/duplicate','POST');await refresh();setStatus('Form copied into a new draft.')}catch(e){setError(String(e))}}
 async function showMap(id:string){try{const x=await request('/dev/forms/'+id+'/mapping');setMapping(JSON.stringify(x,null,2))}catch(e){setError(String(e))}}
 return <section className="panel"><h2>Form Studio — Development Preview</h2><p>Create structured forms, copy templates and preview automatically generated field-to-JSON mappings. No AI inference or clinical publishing enabled.</p>
 <form onSubmit={save} className="note-form"><label>Form name<input required minLength={2} maxLength={160} value={name} onChange={e=>setName(e.target.value)}/></label>
 <h3>Fields</h3>{fields.map((f,i)=><div key={i} className="admin-item">
 <input aria-label="Field key" value={f.id} onChange={e=>edit(i,{id:e.target.value})}/>
 <input aria-label="Field label" value={f.label} onChange={e=>edit(i,{label:e.target.value})}/>
 <select aria-label="Field type" value={f.type} onChange={e=>edit(i,{type:e.target.value as Field['type']})}>{['text','textarea','number','date','boolean'].map(t=><option key={t}>{t}</option>)}</select>
 <label>Required <input type="checkbox" checked={f.required} onChange={e=>edit(i,{required:e.target.checked})}/></label>
 <button type="button" className="secondary" onClick={()=>setFields(xs=>xs.filter((_,j)=>j!==i))}>Remove</button>
 </div>)}
 <div className="actions"><button type="button" className="secondary" onClick={add}>Add field</button><button type="submit">Save draft form</button></div></form>
 <h3>Existing forms</h3>{forms.map(f=><div className="admin-item" key={f.id}><span><strong>{f.name}</strong> <small>v{f.version} · {f.fields.length} fields</small></span><button type="button" onClick={()=>{setName(f.name+' (Edited Copy)');setFields(f.fields)}} className="secondary">Load as copy</button><button type="button" onClick={()=>void duplicate(f.id)}>Duplicate</button><button type="button" className="secondary" onClick={()=>void showMap(f.id)}>View DB mapping</button></div>)}
 {mapping&&<pre className="mapping-preview">{mapping}</pre>}
 <h3>AI import from screenshots and video</h3><p>Planned controlled workflow: upload authorized screenshots/video → extract visible fields and layout → generate a draft React form and typed schema → review mappings → validate in a sandbox → publish only with approval. Video and screenshot AI processing is not yet connected.</p>
 {status&&<p role="status">{status}</p>}{error&&<p role="alert" className="error">{error}</p>}</section>
}
