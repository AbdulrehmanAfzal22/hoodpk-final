import {getProducts,getProduct} from './catalog';
export async function getPublishedProducts(category=null){return (await getProducts()).filter(product=>!category||product.categories?.slug===category);}
export const getProductById=getProduct;
