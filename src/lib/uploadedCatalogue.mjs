import data from '../data/uploadedCatalogue.json' with {type:'json'};
import sweatshirts from '../data/sweatshirtCatalogue.json' with {type:'json'};
import zippers from '../data/zipperCatalogue.json' with {type:'json'};
const paths=new Set([...data.assets,...sweatshirts.assets,...zippers.assets].map(asset=>asset.path));
export const uploadedProducts=data.products;
export const uploadedCategories=data.categories;
export const uploadedProductIds=new Set(data.products.map(product=>product.id));
export function uploadedImageUrl(path){return paths.has(path)?`/assets/catalog/${path}`:null;}
export function normalizeCatalogueProduct(product){if(!product)return product;const source=product.categories;const slug=source?.slug?.replace(/^hood-/,'');const category=uploadedCategories.find(category=>category.slug===slug);return {...product,categories:category?{...source,name:category.name,slug}:source};}
export function mergeUploadedCatalogue(remote=[]){const rows=new Map(uploadedProducts.map(product=>[product.id,structuredClone(product)]));for(const product of remote.filter(product=>product.storefront==='hood'))rows.set(product.id,normalizeCatalogueProduct(product));return [...rows.values()];}
export function filterUploadedProducts(products,{admin=false,categoryId=null,isAccessory=null}={}){return products.filter(product=>(admin||product.status==='published')&&(!categoryId||product.category_id===categoryId||product.categories?.slug===categoryId)&&(isAccessory===null||product.categories?.is_accessory===isAccessory));}
