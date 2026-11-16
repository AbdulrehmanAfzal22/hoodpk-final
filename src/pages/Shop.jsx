import {categoryColourCards} from '../lib/categoryColourCards.mjs';
import {matchesVariantFilters} from '../lib/shopAvailability.mjs';
import {sellingPrice} from '../lib/productPricing';
import {useState} from 'react';
import {useSearchParams} from 'react-router-dom';
import {SlidersHorizontal} from 'lucide-react';
import {getProducts,getActiveCategories} from '../services/catalog';
import {useQuery} from '../hooks/useQuery';
import ShopHeader from '../components/shop/ShopHeader';
import CollectionNav from '../components/shop/CollectionNav';
import FilterSidebar from '../components/shop/FilterSidebar';
import MobileFilterDrawer from '../components/shop/MobileFilterDrawer';
import LuxuryProductGrid from '../components/shop/LuxuryProductGrid';
import {ErrorState} from '../components/Feedback';
import '../styles/shop.css';

export default function Shop(){
  const query=useQuery(()=>Promise.all([getProducts(),getActiveCategories()]));
  const [params,setParams]=useSearchParams();
  const [filterDrawerOpen,setFilterDrawerOpen]=useState(false);
  const [limit,setLimit]=useState(12);

  function change(key,value){
    const next=new URLSearchParams(params);
    value?next.set(key,value):next.delete(key);
    setParams(next);
    setLimit(12);
  }

  function selectCollection(selection){
    const next=new URLSearchParams(params);
    if(selection==='all'){
      next.delete('category');
      if(next.get('sort')==='newest')next.delete('sort');
    }else if(selection==='newest'){
      next.delete('category');
      next.set('sort','newest');
    }else next.set('category',selection);
    setParams(next);
    setLimit(12);
  }

  function clearFilters(){setParams({});setLimit(12);}

  if(query.loading&&!query.data)return <div className="page shop shop-experience"><ShopHeader/><section className="shop-loading"><p className="shop-eyebrow">A moment while we prepare the edit</p><LuxuryProductGrid loading/></section></div>;
  if(query.error)return <div className="page shop shop-experience"><ShopHeader/><div className="shop-error"><ErrorState error={query.error} retry={query.refresh}/></div></div>;

  const [rawProducts,categories]=query.data||[[],[]];
  const products=categoryColourCards(rawProducts);
  const categoryProducts=products.filter(p=>!params.get('category')||p.category_id===params.get('category')||p.categories?.slug===params.get('category'));
  const variants=categoryProducts.filter(product=>!product.is_bundle).flatMap(product=>product.product_variants||[]).filter(variant=>variant.active);
  const enquiryColours=categoryProducts.flatMap(product=>product.enquiry_only?product.inquiry_colours||[]:[]);
  const colors=[...new Map([...variants,...enquiryColours].map(variant=>[variant.color,{name:variant.color,hex:variant.color_hex}])).values()];
  const sizes=[...new Set(variants.map(variant=>variant.size))];
  const filtered=products.filter(product=>(!params.get('q')||(product.name+' '+product.description).toLowerCase().includes(params.get('q').toLowerCase()))&&(!params.get('category')||(product.category_id===params.get('category')||product.categories?.slug===params.get('category')))&&(!params.get('max')||(!product.enquiry_only&&sellingPrice(product)<=Number(params.get('max'))*100))&&matchesVariantFilters(product,{color:params.get('color'),size:params.get('size'),stock:!!params.get('stock')}));
  filtered.sort((a,b)=>params.get('sort')==='price-low'?sellingPrice(a)-sellingPrice(b):params.get('sort')==='price-high'?sellingPrice(b)-sellingPrice(a):params.get('sort')==='name'?a.name.localeCompare(b.name):new Date(b.created_at)-new Date(a.created_at));
  const activeFilterCount=['q','category','max','color','size','stock'].filter(key=>params.has(key)).length;

  return <div className="page shop shop-experience">
    <ShopHeader/>
    <CollectionNav categories={categories} params={params} onSelect={selectCollection}/>
    <div className="shop-toolbar">
      <p className="shop-toolbar__count"><strong>{filtered.length}</strong><span>{filtered.length===1?'piece':'pieces'}</span></p>
      <div className="shop-toolbar__actions">
        <button type="button" className="shop-filter-trigger" onClick={()=>setFilterDrawerOpen(true)} aria-expanded={filterDrawerOpen}><SlidersHorizontal size={16}/><span>Filters</span>{activeFilterCount>0&&<span className="shop-filter-trigger__count">{activeFilterCount}</span>}</button>
        <label className="shop-sort"><span>Sort by</span><select value={params.get('sort')||''} onChange={event=>change('sort',event.target.value)}><option value="">Newest</option><option value="price-low">Price: low to high</option><option value="price-high">Price: high to low</option><option value="name">Name</option></select></label>
      </div>
    </div>
    <div className="shop-layout">
      <FilterSidebar categories={categories} colors={colors} sizes={sizes} params={params} change={change} onClear={clearFilters}/>
      <section className="shop-results" aria-label="Products">
        <LuxuryProductGrid products={filtered.slice(0,limit)} emptyTitle={products.length?'No pieces found':'The collection is taking shape'} emptyDescription={products.length?'Try another selection.':'New pieces will appear here as soon as they are published.'} onClear={activeFilterCount?clearFilters:null} hasMore={filtered.length>limit} onLoadMore={()=>setLimit(current=>current+12)}/>
      </section>
    </div>
    <MobileFilterDrawer open={filterDrawerOpen} onClose={()=>setFilterDrawerOpen(false)} categories={categories} colors={colors} sizes={sizes} params={params} change={change} onClear={clearFilters} count={filtered.length}/>
  </div>;
}
