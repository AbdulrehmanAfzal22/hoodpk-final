import { supabase } from "../lib/supabase";

// profiles and orders both reference auth.users but have no FK to each
// other, so PostgREST can't embed them together. Fetch separately and merge.
export async function getCustomers() {
  const { data: memberships, error } = await supabase
    .from("hood_customers")
    .select("user_id,profiles(*)")
    .order("created_at", { ascending: false });
  if (error) throw error;
  const profiles=(memberships||[]).map(member=>member.profiles).filter(Boolean);

  const { data: orders, error: oErr } = await supabase
    .from("orders")
    .select("id,user_id,status,total_cents,created_at").eq('storefront','hood');
  if (oErr) throw oErr;

  const byUser = {};
  for (const o of orders || []) (byUser[o.user_id] ||= []).push(o);

  return (profiles || []).map((p) => ({ ...p, orders: byUser[p.id] || [] }));
}

export async function getCustomerById(userId) {
  const membership=await supabase.from('hood_customers').select('user_id').eq('user_id',userId).maybeSingle();if(membership.error)throw membership.error;if(!membership.data)throw new Error('HOOD customer not found');
  const [{ data: profile, error }, { data: addresses, error: aErr }, { data: orders, error: oErr }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).single(),
      supabase.from("addresses").select("*").eq("user_id", userId),
      supabase.from("orders").select("*,order_items(*)").eq("user_id", userId).order("created_at", { ascending: false }).eq('storefront','hood'),
    ]);
  if (error) throw error;
  if (aErr) throw aErr;
  if (oErr) throw oErr;

  return { ...profile, addresses: addresses || [], orders: orders || [] };
}
