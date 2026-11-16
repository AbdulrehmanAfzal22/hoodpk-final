export function bundleCardTiles(product){
 const components=product?.bundle_components||[];
 if(components.length)return components.map(component=>({id:component.id,name:component.name,path:[...(component.product_images||[])].sort((a,b)=>a.position-b.position)[0]?.path||null}));
 return [...(product?.product_images||[])].sort((a,b)=>a.position-b.position).map((image,i)=>({id:image.id||String(i),name:image.alt||'Included product',path:image.path}));
}
