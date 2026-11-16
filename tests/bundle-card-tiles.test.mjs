import test from 'node:test';import assert from 'node:assert/strict';
import {bundleCardTiles} from '../src/lib/bundleCardTiles.mjs';
test('bundle collage includes every component and uses its first ordered photograph',()=>{
 const components=Array.from({length:9},(_,i)=>({id:String(i),name:`Product ${i}`,product_images:[{position:2,path:`${i}-b.png`},{position:0,path:`${i}-a.png`}]}));
 const tiles=bundleCardTiles({bundle_components:components});assert.equal(tiles.length,9);assert.deepEqual(tiles.map(t=>t.path),components.map((_,i)=>`${i}-a.png`));
});
test('missing photos keep their bundle slot and legacy image lists still render',()=>{
 assert.equal(bundleCardTiles({bundle_components:[{id:'a',name:'A',product_images:[]}]}).length,1);
 assert.equal(bundleCardTiles({product_images:[{path:'cover.png',position:0}]}).length,1);
});
