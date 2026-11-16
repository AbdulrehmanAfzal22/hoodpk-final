import {hydrateBundles} from './bundles';
import { supabase, unwrap } from "../lib/supabase";

const cartSelect = "variant_id,quantity,customisation_note,bundle_selection,product_variants!inner(*,products!inner(*,product_images(*)))";

export function notifyCartChanged(source){
  window.dispatchEvent(new CustomEvent('maison:cart-changed',{detail:{source}}));
}

export async function getCart(userId) {
  if (!userId) return [];
  let result=await supabase.from('cart_items').select(cartSelect).eq('product_variants.products.storefront','hood').eq('user_id',userId);
  // Keep existing carts working while the bundle migration awaits approval.
  if(result.error&&result.error.message?.includes('bundle_selection'))result=await supabase.from('cart_items').select(cartSelect.replace('bundle_selection,','')).eq('product_variants.products.storefront','hood').eq('user_id',userId);
  const {data,error}=result;

  if (error) throw error;
  const products=await hydrateBundles((data||[]).map(item=>item.product_variants?.products).filter(Boolean));
  return (data||[]).map(item=>({...item,product_variants:{...item.product_variants,products:products.find(p=>p.id===item.product_variants?.products?.id)}}));
}

export async function addToCart(variantId, quantity = 1, note = "") {
  const result=unwrap(await supabase.rpc("hood_add_to_cart_with_note", { p_variant_id: variantId, p_quantity: quantity, p_note: note.trim() }));
  notifyCartChanged();
  return result;
}

export async function updateCartItem(variantId, quantity, source) {
  const result=unwrap(await supabase.rpc("hood_set_cart_quantity", { p_variant_id: variantId, p_quantity: quantity }));
  notifyCartChanged(source);
  return result;
}

export async function removeCartItem(variantId, source) {
  const result=unwrap(await supabase.rpc("hood_remove_from_cart", { p_variant_id: variantId }));
  notifyCartChanged(source);
  return result;
}
