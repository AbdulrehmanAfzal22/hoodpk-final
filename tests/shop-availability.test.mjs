import test from 'node:test';
import assert from 'node:assert/strict';
import {matchesVariantFilters} from '../src/lib/shopAvailability.mjs';
test('published priced products remain discoverable before inventory is configured',()=>{
 const p={enquiry_only:false,product_variants:[]};
 assert.equal(matchesVariantFilters(p),true);
 assert.equal(matchesVariantFilters(p,{stock:true}),false);
 assert.equal(matchesVariantFilters(p,{size:'M'}),false);
});
test('colour, size and stock must match the same active variant',()=>{
 const p={product_variants:[{active:true,color:'Black',size:'M',stock:10},{active:true,color:'Red',size:'L',stock:0}]};
 assert.equal(matchesVariantFilters(p,{color:'Black',size:'M',stock:true}),true);
 assert.equal(matchesVariantFilters(p,{color:'Red',stock:true}),false);
 assert.equal(matchesVariantFilters(p,{color:'Black',size:'L'}),false);
});
