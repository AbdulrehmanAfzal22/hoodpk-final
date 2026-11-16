import {Banknote,WalletCards,Check} from 'lucide-react';
import {money} from '../../lib/supabase';
import styles from './PaymentMethodChoice.module.css';

export default function PaymentMethodChoice({method,onChange,contactNumber,onContactChange,amount,advanceRequired=false,busy=false}){
 const options=[{id:'cod',title:'Cash on Delivery',description:'Pay when your order arrives',Icon:Banknote},{id:'bank_transfer',title:'Bank Transfer',description:'Bank account or EasyPaisa',Icon:WalletCards}];
 function handleArrow(event,index){if(!['ArrowRight','ArrowDown','ArrowLeft','ArrowUp'].includes(event.key))return;event.preventDefault();const next=options[(index+1)%options.length];if(busy||(advanceRequired&&next.id==='cod'))return;onChange(next.id);event.currentTarget.parentElement.querySelector(`[data-method="${next.id}"]`)?.focus();}
 return <section className={styles.section} aria-labelledby="payment-choice-title">
  <header className={styles.heading}><span className={styles.step}>02</span><div><p className={styles.eyebrow}>Payment method</p><h2 className={styles.title} id="payment-choice-title">How would you like to pay?</h2></div></header>
  <div className={styles.options} role="radiogroup" aria-label="Payment method">{options.map(({id,title,description,Icon},index)=><button type="button" role="radio" data-method={id} aria-checked={method===id} key={id} className={styles.card} onClick={()=>onChange(id)} onKeyDown={event=>handleArrow(event,index)} disabled={busy||(advanceRequired&&id==='cod')}><span className={styles.icon}><Icon size={20} aria-hidden="true"/></span><span className={styles.copy}><strong>{title}</strong><small>{description}</small></span><span className={styles.dot} aria-hidden="true">{method===id&&<Check/>}</span></button>)}</div>
  {method==='cod'&&!advanceRequired&&<div className={styles.details}><p className={styles.total}><span>Pay on delivery</span><strong>{money(amount)}</strong></p><p className={styles.note}>Pay in cash when your parcel arrives. No advance payment or screenshot needed.</p><label className={styles.field} htmlFor="cod-contact-number"><span>Contact number <span aria-hidden="true" style={{color:'#ff4758'}}>*</span></span><input id="cod-contact-number" name="phone" type="tel" autoComplete="tel" value={contactNumber} onChange={e=>onContactChange(e.target.value)} required maxLength={25} disabled={busy} placeholder="03XXXXXXXXX or +923XXXXXXXXX"/></label><small className={styles.helper}>We’ll use this number to confirm your order and arrange delivery.</small></div>}
 </section>;
}
