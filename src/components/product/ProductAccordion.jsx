import {ChevronDown} from 'lucide-react';

export default function ProductAccordion({product}){
  const sections=[
    {title:'Description',content:product.description||'Product details will be shared soon.'},
    {title:'Materials',content:product.materials||product.ingredients||'For composition details, please contact THE HOOD.PK team.'},
    {title:'Shipping',content:'Fixed delivery charges of Rs. 300 across Pakistan. Orders are generally delivered within 3–7 working days.'},
    {title:'Care instructions',content:product.care||'Care instructions will be included with your piece.'},
  ];

  return <section className="product-accordion" aria-label="Product details">{sections.map((section,index)=><details key={section.title} open={index===0}><summary><span>{section.title}</span><ChevronDown size={17}/></summary><p>{section.content}</p></details>)}</section>;
}