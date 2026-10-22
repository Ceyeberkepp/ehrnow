import {useState,type FormEvent} from 'react';
type Props={request:(path:string,method?:string,body?:unknown)=>Promise<any>;onSignedOut:()=>void};
export default function AdminSecurity({request,onSignedOut}:Props){
 const [current,setCurrent]=useState('');const [next,setNext]=useState('');const [confirm,setConfirm]=useState('');const [busy,setBusy]=useState(false);const [error,setError]=useState('');
 async function submit(e:FormEvent){e.preventDefault();setError('');
 if(next!==confirm){setError('New passwords do not match');return}
 if(next.length<14){setError('Use at least 14 characters');return}
 setBusy(true);try{await request('/auth/password','POST',{current_password:current,new_password:next});setCurrent('');setNext('');setConfirm('');onSignedOut()}catch(e){setError(String(e))}finally{setBusy(false)}
 }
 return <section className="panel"><h2>Global Administrator — Account Security</h2><p>Development administrator password management. Changing your password invalidates all active sessions, including this one.</p><form onSubmit={submit} className="form">
 <label>Current password<input required type="password" autoComplete="current-password" value={current} onChange={e=>setCurrent(e.target.value)}/></label>
 <label>New password<input required minLength={14} maxLength={256} type="password" autoComplete="new-password" value={next} onChange={e=>setNext(e.target.value)}/></label>
 <label>Confirm new password<input required type="password" autoComplete="new-password" value={confirm} onChange={e=>setConfirm(e.target.value)}/></label>
 <div className="actions"><button disabled={busy||!current||next!==confirm} type="submit">Change password and sign out</button></div></form>
 {error&&<p role="alert" className="error">{error}</p>}
 <p>Additional security controls—MFA, lockout protection, per-user authorization, and security event auditing—remain in development. This is not ready for real patient information.</p></section>;
}
