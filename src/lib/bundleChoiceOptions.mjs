export const categoryWideBundleSlugs=['plain-hoodies','sweatshirts','zipper-hoodies'];
export function bundleChoiceOptions(component){return (component.bundle_choice_products||[component]).flatMap(product=>(product.product_variants||[]).filter(variant=>variant.active).map(variant=>({product,variant})));}
