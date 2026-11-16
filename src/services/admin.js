import {supabase} from '../lib/supabase';
export async function checkAdminAccess(userId){if(!userId)return false;const {data:{user}}=await supabase.auth.getUser();if(user?.id!==userId)return false;const {data,error}=await supabase.rpc('is_admin');if(error)throw error;return Boolean(data);}
