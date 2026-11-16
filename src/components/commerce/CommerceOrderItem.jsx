import {Package} from 'lucide-react';
import {imageUrl,money} from '../../lib/supabase';
import BundleContents from '../BundleContents';
import CustomisationNote from '../CustomisationNote';
import '../../styles/order-item-layout.css';
export default function CommerceOrderItem({item,currency='PKR'}){
 const contents=item.bundle_selection||[],isBundle=contents.length>0;
 const image=item.image_path||contents.find(piece=>piece.image_path)?.image_path;
 return <article className="commerce-item"><div className="commerce-item__header"><div className="commerce-item__photo">{image?<img src={imageUrl(image)} alt={item.product_name||'Ordered item'} loading="lazy"/>:<Package size={23} aria-hidden="true"/>}</div><div className="commerce-item__title"><h3>{item.product_name||'Unavailable product'}</h3><p>{isBundle?`${contents.length} items in this bundle`:[item.color,item.size&&`Size ${item.size}`].filter(Boolean).join(' · ')}<span>Quantity: {item.quantity}</span></p></div><strong className="commerce-item__price">{money(item.unit_price_cents*item.quantity,currency)}</strong></div>{(isBundle||item.customisation_note)&&<div className="commerce-item__details"><BundleContents items={contents}/><CustomisationNote note={item.customisation_note}/></div>}</article>;
}
