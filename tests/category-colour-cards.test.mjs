import test from 'node:test';import assert from 'node:assert/strict';
import {categoryColourCards,productCardHref} from '../src/lib/categoryColourCards.mjs';
import {bundleChoiceOptions} from '../src/lib/bundleChoiceOptions.mjs';
test('each hoodie colour gets its own photo, options and detail URL without duplicating database products',()=>{
 const p={id:'hoodie',name:'Plain Hoodie — 14 Colours',categories:{slug:'plain-hoodies'},product_variants:[{id:'r',active:true,color:'Red',size:'M'},{id:'b',active:true,color:'Blue',size:'M'}],product_images:[{path:'red.jpg',color:'Red',position:0},{path:'blue.jpg',color:'Blue',position:1}]};
 const cards=categoryColourCards([p]);assert.equal(cards.length,2);assert.equal(cards[1].product_images[0].path,'blue.jpg');assert.equal(cards[1].product_variants.length,1);assert.equal(cards[1].id,'hoodie');assert.equal(productCardHref(cards[1]),'/product/hoodie?colour=Blue');
});
test('bundle slots can expose options from sibling colour listings, but retain actual product ownership',()=>{
 const seed={id:'maroon',bundle_choice_products:[{id:'maroon',product_variants:[{id:'m',active:true,color:'Maroon',size:'M'}]},{id:'white',product_variants:[{id:'w',active:true,color:'White',size:'L'}]}]};const options=bundleChoiceOptions(seed);assert.equal(options.length,2);assert.equal(options[1].product.id,'white');assert.equal(options[1].variant.color,'White');
});
