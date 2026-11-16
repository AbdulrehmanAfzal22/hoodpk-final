import CommerceOrderItem from './CommerceOrderItem';
import {sellingPrice} from '../../lib/productPricing';
import {LockKeyhole,ShieldCheck} from 'lucide-react';
import {Link} from 'react-router-dom';
import {money,imageUrl} from '../../lib/supabase';
import {galleryImages} from '../../lib/productOptions';

export default function OrderSummary({items=[],subtotal,shipping=0,unavailable=false,busy=false,formId,disabled=false,paymentMethod='cod',advanceRequired=false,payableNow,balanceOnDelivery}){
  return <aside className="commerce-summary checkout-order-summary" id="order-summary" aria-labelledby="checkout-summary-title">
    <div className="checkout-order-summary__top"><p className="commerce-eyebrow">The final edit</p><h2 id="checkout-summary-title">Your order</h2><span>{items.length} {items.length===1?'piece':'pieces'}</span></div>
    <div className="checkout-order-summary__items">{items.map(item=>{
      const variant=item.product_variants;
      const product=variant?.products;
      const image=galleryImages(product?.product_images,variant?.color)[0];
      return <CommerceOrderItem key={item.variant_id} item={{...item,product_name:product?.name||'Unavailable piece',image_path:image?.path,color:variant?.color,size:variant?.size,unit_price_cents:sellingPrice(product)}}/>;
    })}</div>
    <dl className="commerce-summary__rows"><div><dt>Subtotal</dt><dd>{money(subtotal)}</dd></div><div><dt>Shipping</dt><dd className="commerce-summary__free">{shipping===0?'Complimentary':money(shipping)}</dd></div></dl>
    <div className="commerce-summary__total"><span>{advanceRequired?'Order total':paymentMethod==='bank_transfer'?'Total to transfer':'Total due on delivery'}</span><strong>{money(subtotal+shipping)}</strong></div>
    {advanceRequired&&<dl className="commerce-summary__rows"><div><dt>50% advance due now</dt><dd>{money(payableNow)}</dd></div><div><dt>Balance on delivery</dt><dd>{money(balanceOnDelivery)}</dd></div></dl>}
    <div className="checkout-payment-note" id="delivery"><ShieldCheck size={18}/><div><strong>Delivery across Pakistan</strong><span>{paymentMethod==='bank_transfer'?'Bank Transfer / EasyPaisa · Verified by our team':'Cash on delivery · Pay when your order arrives'}</span></div></div>
    {unavailable?<p className="commerce-summary__notice" role="alert">Some pieces are unavailable. <Link to="/cart">Update your collection</Link> before placing the order.</p>:<button className="commerce-primary-button" style={{border:'2px solid #ce1024',borderRadius:8,background:'#111',color:'#fff',padding:'16px 18px',width:'100%',minHeight:54,lineHeight:1.6}} type="submit" form={formId} disabled={busy||disabled}>{busy?(paymentMethod==='cod'?'Placing your order…':'Submitting your payment…'):`${paymentMethod==='cod'?'Place Cash on Delivery order':'Submit payment & order'} · ${money(advanceRequired?payableNow:subtotal+shipping)}`}</button>}
    <p className="commerce-secure-note"><LockKeyhole size={14}/> Your information is protected</p>
  </aside>;
}