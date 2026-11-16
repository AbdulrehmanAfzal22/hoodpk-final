import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import data from '../src/data/zipperCatalogue.json' with {type:'json'};
import {uploadedImageUrl} from '../src/lib/uploadedCatalogue.mjs';
test('four zipper colours use the supplied photos and resolve to packaged assets',()=>{
 assert.deepEqual(data.products.map(p=>p.color),['Black','Grey','Navy Blue','Maroon']);
 assert.equal(new Set(data.products.map(p=>p.id)).size,4);
 for(const p of data.products){const asset=data.assets.find(a=>a.path===p.path);assert.ok(asset);const bytes=readFileSync(new URL('../public/assets/catalog/'+p.path,import.meta.url));assert.equal(createHash('sha256').update(bytes).digest('hex'),asset.sha256);assert.equal(uploadedImageUrl(p.path),'/assets/catalog/'+p.path);}
});
