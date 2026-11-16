import {sellingPrice} from '../../lib/productPricing';
import {Link} from 'react-router-dom';
import {ArrowUpRight,Check,Truck} from 'lucide-react';
import {money} from '../../lib/supabase';

export default function ProductInfo({product,selectedVariant,children}){
  const category=product.categories;
  const available=Boolean(selectedVariant&&selectedVariant.stock>0);

  return <section className="product-info" aria-labelledby="product-title">
    <nav className="product-breadcrumbs" aria-label="Breadcrumb">
      <Link to="/">Home</Link><span aria-hidden="true">/</span><Link to={category?.slug?`${category.is_accessory?'/accessories':'/collections'}/${encodeURIComponent(category.slug)}`:'/shop'}>{category?.name||'Collection'}</Link><span aria-hidden="true">/</span><span aria-current="page">{product.name}</span>
    </nav>
    <p className="product-info__category">{category?.name||'the HOOD · Collection'}</p>
    <h1 id="product-title">{product.name}</h1>
    <p className="product-info__price">{product.enquiry_only?'Price on request':money(sellingPrice(product))}</p>
    <p className="product-info__description">{product.description}</p>
    <p className={`product-stock ${available?'product-stock--available':''}`} role="status">{product.is_bundle?'One fixed price · Choose options for each included item':product.enquiry_only?'Enquire for pricing and availability':available?<><Check size={15}/> In stock · Ready to ship</>:(product.product_variants||[]).some(variant=>variant.active)?'Select a size to check availability':'Sizes and stock are being updated'}</p>
    {children}
    <div className="product-shipping-note"><Truck size={17}/><p><strong>Delivery · Rs. 300</strong><span>Across Pakistan · Generally 3–7 working days.</span></p><ArrowUpRight size={15}/></div>
  </section>;
}