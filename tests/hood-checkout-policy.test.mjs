import test from 'node:test';
import assert from 'node:assert/strict';
import {checkoutPolicy,DELIVERY_CENTS} from '../src/lib/checkoutPolicy.mjs';
import {paymentOptions} from '../src/lib/paymentOptions.js';
test('delivery and advance policy handles exact threshold and one-paisa boundary',()=>{assert.equal(DELIVERY_CENTS,30000);assert.deepEqual(checkoutPolicy(970000),{total:1000000,advanceRequired:false,payableNow:1000000,balanceOnDelivery:0});assert.deepEqual(checkoutPolicy(970001),{total:1000001,advanceRequired:true,payableNow:500001,balanceOnDelivery:500000});assert.equal(checkoutPolicy(100000).total,130000);});
test('EasyPaisa appears only after an active receiving account is configured',()=>{assert.deepEqual(paymentOptions(null),[]);assert.equal(paymentOptions({easypaisa_active:false,easypaisa_number:'03000000000'}).length,0);assert.equal(paymentOptions({easypaisa_active:true,easypaisa_number:'03000000000'})[0].id,'easypaisa');assert.equal(paymentOptions({easypaisa_active:true,easypaisa_number:''}).length,0);});
