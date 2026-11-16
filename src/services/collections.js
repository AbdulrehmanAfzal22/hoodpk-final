import {getProducts} from './catalog';
export async function getFeaturedProducts(){return (await getProducts()).filter(product=>product.featured);}
export async function getNewArrivals(){return (await getProducts()).sort((a,b)=>new Date(b.created_at)-new Date(a.created_at)).slice(0,12);}
