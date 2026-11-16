import {DELIVERY_CENTS,checkoutPolicy} from '../../lib/checkoutPolicy.mjs';
import {LockKeyhole,ArrowRight} from 'lucide-react';
import {Link} from 'react-router-dom';
import {money} from '../../lib/supabase';

export default function CartSummary({subtotal,unavailable}){
  return <aside className="commerce-summary cart-order-summary" aria-labelledby="cart-summary-title">
    <p className="commerce-eyebrow">A considered choice</p>
    <h2 id="cart-summary-title">Order summary</h2>
    <dl className="commerce-summary__rows"><div><dt>Subtotal</dt><dd>{money(subtotal)}</dd></div><div><dt>Shipping</dt><dd className="commerce-summary__free">{money(DELIVERY_CENTS)}</dd></div><div><dt>Discount</dt><dd>—</dd></div></dl>
    <div className="commerce-summary__total"><span>Total</span><strong>{money(subtotal+DELIVERY_CENTS)}</strong></div>
    {unavailable?<p className="commerce-summary__notice" role="alert">Update unavailable pieces before continuing to checkout.</p>:<Link className="commerce-primary-button" to="/checkout">Proceed to checkout <ArrowRight size={17}/></Link>}
    {checkoutPolicy(subtotal).advanceRequired&&<p className="hood-advance-notice">50% advance required for this order via Bank Transfer / EasyPaisa. Balance due on delivery.</p>}
    <p className="commerce-secure-note"><LockKeyhole size={14}/> Secure checkout · Your details are protected</p>
    <p className="commerce-summary__shipping-note">Fixed delivery charges: Rs. 300 across Pakistan.</p>
  </aside>;
}