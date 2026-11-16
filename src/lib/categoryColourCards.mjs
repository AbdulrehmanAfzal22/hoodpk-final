import {normaliseColour,galleryImages} from './productOptions.js';
const splitCategories=new Set(['plain-hoodies','sweatshirts','zipper-hoodies']);
export function categoryColourCards(products){return products.flatMap(product=>{
 if(product.is_bundle||!splitCategories.has(product.categories?.slug))return [product];
 const colours=[...new Map((product.product_variants||[]).filter(v=>v.active).map(v=>[normaliseColour(v.color),v.color])).values()];
 if(colours.length<2)return [product];
 const base=product.name.replace(/\s*[—–-]\s*\d+\s*colou?rs?\s*$/i,'');
 return colours.map(color=>({...product,name:`${base} — ${color}`,card_colour:color,display_key:`${product.id}:${normaliseColour(color)}`,product_images:galleryImages(product.product_images,color),product_variants:product.product_variants.filter(v=>normaliseColour(v.color)===normaliseColour(color)),inquiry_colours:(product.inquiry_colours||[]).filter(v=>normaliseColour(v.color)===normaliseColour(color))}));
});}
export function productCardHref(product){return `/product/${product.id}${product.card_colour?`?colour=${encodeURIComponent(product.card_colour)}`:''}`;}
