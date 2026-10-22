import {ArrowLeft,IdCard,CalendarDays,ShieldAlert} from 'lucide-react';
type Patient={id:string;mrn:string;given_name:string;family_name:string;birth_date:string};
export default function PatientSummary({patient,onBack}:{patient:Patient;onBack:()=>void}){
 return <section className="patient-summary">
  <button className="secondary" onClick={onBack}><ArrowLeft size={16}/> Back to Patient Registry</button>
  <section className="panel"><small>Synthetic patient record</small><h2>{patient.given_name} {patient.family_name}</h2><div className="patient-fields"><div><IdCard size={20}/><span><small>Medical record number</small><strong>{patient.mrn}</strong></span></div><div><CalendarDays size={20}/><span><small>Date of birth</small><strong>{patient.birth_date}</strong></span></div><div><IdCard size={20}/><span><small>Record ID</small><strong className="mono">{patient.id}</strong></span></div></div></section>
  <section className="panel"><h2>Chart sections</h2><p><ShieldAlert size={16}/> This read-only demographic summary does not imply that the complete clinical chart is implemented. Use the separate Encounters, Problem List and Reported Allergies workspaces for their available development features.</p></section>
 </section>
}
