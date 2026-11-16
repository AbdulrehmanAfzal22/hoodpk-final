import {uploadedImageUrl} from './uploadedCatalogue.mjs';
import { createClient } from '@supabase/supabase-js';
import {demoImageUrl} from './demoImages';
import {readAuthRedirect} from './authCallback.mjs';
// Capture recovery type/returnTo before the SDK consumes the URL fragment.
export const initialAuthRedirect=typeof window==='undefined'?null:readAuthRedirect(window.location.href);
export const supabaseUrl=import.meta.env.VITE_SUPABASE_URL || 'https://oapkgdvsnpakpackmgcs.supabase.co';
export const supabasePublishableKey=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_J-xAECaiKT2anzSNNA3weA_u0Wq3YND';
export const supabase = createClient(
  supabaseUrl,
  supabasePublishableKey,
  {auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,flowType:initialAuthRedirect?.code?'pkce':'implicit',storageKey:'cloth-web-auth'}}
);
export const imageUrl = path => path ? uploadedImageUrl(path)||demoImageUrl(path)||supabase.storage.from('product-images').getPublicUrl(path).data.publicUrl : null;
export const categoryImageUrl = path => path ? uploadedImageUrl(path)||supabase.storage.from('category-images').getPublicUrl(path).data.publicUrl : null;
export function unwrap({data,error}) { if(error) throw error; return data; }
export {money} from './money';
