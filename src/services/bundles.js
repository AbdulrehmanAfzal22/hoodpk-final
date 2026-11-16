import {categoryWideBundleSlugs} from '../lib/bundleChoiceOptions.mjs';
import {supabase,unwrap} from '../lib/supabase';
import {normalizeCatalogueProduct} from '../lib/uploadedCatalogue.mjs';
export async function hydrateBundles(products){
 const ids=products.filter(p=>p?.is_bundle).map(p=>p.id);if(!ids.length)return products;
 const r=await supabase.from('hood_bundle_items').select('bundle_product_id,position,products!hood_bundle_items_product_id_fkey(*,product_images(*),product_variants(*),categories(id,name,slug))').in('bundle_product_id',ids).order('position');if(r.error)throw r.error;
 const seedProducts=(r.data||[]).map(row=>normalizeCatalogueProduct(row.products)).filter(Boolean);
 const categoryIds=[...new Set(seedProducts.filter(p=>categoryWideBundleSlugs.includes(p.categories?.slug)).map(p=>p.category_id))];
 let siblings=[];
 if(categoryIds.length){const choices=await supabase.from('products').select('*,categories(id,name,slug),product_images(*),product_variants(*)').eq('storefront','hood').eq('status','published').eq('is_bundle',false).eq('enquiry_only',false).in('category_id',categoryIds);if(choices.error)throw choices.error;siblings=(choices.data||[]).map(normalizeCatalogueProduct);}
 return products.map(p=>{if(!p.is_bundle)return p;const rows=(r.data||[]).filter(x=>x.bundle_product_id===p.id),components=rows.map(x=>normalizeCatalogueProduct(x.products)).filter(Boolean).map(seed=>({...seed,bundle_choice_products:categoryIds.includes(seed.category_id)?siblings.filter(p=>p.category_id===seed.category_id):[seed]}));return {...p,bundle_components:components,bundle_expected_count:rows.length,product_images:components.map(x=>[...(x.product_images||[])].sort((a,b)=>a.position-b.position)[0]).filter(Boolean).map((im,i)=>({...im,position:i,color:null}))};});
}
export async function saveBundle(form){const result=await supabase.rpc('hood_save_bundle',{p_id:form.id||null,p_name:form.name,p_description:form.description,p_price:Math.round(Number(form.price)*100),p_products:form.productIds,p_status:form.status});if(result.error?.code==='PGRST202')throw new Error('Bundle creation is waiting for the backend update to be approved and applied.');return unwrap(result);}
export async function addBundleToCart(id,selections,quantity,note){unwrap(await supabase.rpc('hood_add_bundle_to_cart',{p_product_id:id,p_selections:selections,p_quantity:quantity,p_note:note.trim()}));window.dispatchEvent(new CustomEvent('maison:cart-changed'));}
