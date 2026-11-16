import {Star} from 'lucide-react';
import {Link} from 'react-router-dom';
import {useQuery} from '../hooks/useQuery';
import {getProducts} from '../services/catalog';
import {supabase,unwrap} from '../lib/supabase';
export default function CustomerReviews(){
 const q=useQuery(async()=>{const ids=(await getProducts()).map(product=>product.id);if(!ids.length)return [];return unwrap(await supabase.from('reviews').select('id,rating,comment,product_id,created_at').in('product_id',ids).eq('approved',true).order('created_at',{ascending:false}).limit(6));},[]);
 const reviews=q.data||[];
 return <section className="hood-section hood-home-reviews"><div className="hood-section__heading"><div><p className="hood-kicker">From the community</p><h2>Customer <em>Reviews.</em></h2></div></div>{q.loading?<p role="status">Loading reviews…</p>:q.error?<div className="hood-section__empty"><p>Reviews are temporarily unavailable.</p><button className="button outline" type="button" onClick={q.refresh}>Try again</button></div>:reviews.length?<div className="hood-review-grid">{reviews.map(review=><article key={review.id}><div aria-label={`${review.rating} out of 5 stars`}>{Array.from({length:5},(_,i)=><Star key={i} size={15} fill={i<review.rating?'currentColor':'none'} aria-hidden="true"/>)}</div><blockquote>{review.comment}</blockquote><Link to={`/product/${review.product_id}`}>View product ↗</Link></article>)}</div>:<div className="hood-section__empty"><Star size={26} aria-hidden="true"/><p>No customer reviews yet.</p><p>Genuine submissions will appear here once approved.</p></div>}</section>;
}
