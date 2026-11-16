export function matchesVariantFilters(product,{color='',size='',stock=false}={}){
 const active=(product.product_variants||[]).filter(variant=>variant.active);
 if(!color&&!size&&!stock)return true;
 if(product.enquiry_only)return !size&&!stock&&(!color||(product.inquiry_colours||[]).some(option=>option.color===color));
 return active.some(variant=>(!color||variant.color===color)&&(!size||variant.size===size)&&(!stock||variant.stock>0));
}
