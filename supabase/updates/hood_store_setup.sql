-- THE HOOD.PK store setup. Apply after the packaged base migrations.
-- Does not publish products, manufacture reviews, or send messages.
BEGIN;
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_number text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_title text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_active boolean NOT NULL DEFAULT false;
ALTER TABLE public.bank_transfer_settings DROP CONSTRAINT IF EXISTS easypaisa_account_check;
ALTER TABLE public.bank_transfer_settings ADD CONSTRAINT easypaisa_account_check CHECK (NOT easypaisa_active OR easypaisa_number ~ '^0[0-9]{10}$');
ALTER TABLE public.payment_submissions DROP CONSTRAINT IF EXISTS payment_submissions_payment_provider_check;
ALTER TABLE public.payment_submissions ADD CONSTRAINT payment_submissions_payment_provider_check CHECK(payment_provider IN ('bank_alfalah','jazzcash','easypaisa'));
ALTER TABLE public.payment_submissions ADD COLUMN IF NOT EXISTS amount_cents bigint CHECK(amount_cents>0);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS expected_advance_cents bigint NOT NULL DEFAULT 0 CHECK(expected_advance_cents>=0);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS advance_paid_cents bigint NOT NULL DEFAULT 0 CHECK(advance_paid_cents>=0);
-- Remove only known inherited Bella payment defaults, never an independently configured account.
UPDATE public.bank_transfer_settings SET account_number='',active=false WHERE account_number='02351010329869';
UPDATE public.bank_transfer_settings SET jazzcash_number='',jazzcash_active=false WHERE jazzcash_number='03210044435';
UPDATE public.bank_transfer_settings SET whatsapp_number='923098670057' WHERE id;
INSERT INTO public.categories(name,slug,description,is_accessory,is_active,display_order) VALUES
('Customised Hoodies','customised-hoodies','Your design, your rules. Customise through WhatsApp.',false,true,1),
('Printed','printed','Printed designs and options.',false,true,2),
('Plain Hoodies','plain-hoodies','Everyday hoodie essentials.',false,true,3),
('Zipper Hoodies','zipper-hoodies','Easy layers for your wardrobe.',false,true,4),
('Sweatshirts','sweatshirts','Everyday sweatshirts.',false,true,5),
('T-Shirts','t-shirts','Ready-to-wear and customisable T-shirts.',false,true,6),
('Combo Deals / Bundles','combo-deals-bundles','Sets and combo deals.',false,true,7)
ON CONFLICT(slug) DO UPDATE SET name=excluded.name,description=excluded.description,is_active=true,display_order=excluded.display_order;
CREATE OR REPLACE FUNCTION private.checkout_impl(p_shipping jsonb, p_shipping_cents integer, p_request_id uuid)
 RETURNS TABLE(order_id uuid, order_number bigint, total_cents bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  uid uuid := auth.uid();
  new_order_id uuid;
  new_order_number bigint;
  subtotal bigint;
  address jsonb;
  item record;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000'; END IF;
  IF p_request_id IS NULL THEN RAISE EXCEPTION 'Checkout request ID is required' USING ERRCODE='22023'; END IF;
  IF coalesce(p_shipping_cents,0) NOT IN (0,30000) THEN RAISE EXCEPTION 'Delivery is fixed at Rs. 300' USING ERRCODE='22023'; END IF;
  INSERT INTO public.carts(user_id) VALUES(uid) ON CONFLICT DO NOTHING;
  -- The same cart lock is taken by all three cart mutations.
  PERFORM 1 FROM public.carts c WHERE c.user_id=uid FOR UPDATE;
  RETURN QUERY SELECT o.id,o.order_number,o.total_cents FROM public.orders o WHERE o.user_id=uid AND o.request_id=p_request_id;
  IF FOUND THEN RETURN; END IF;

  IF p_shipping IS NULL OR jsonb_typeof(p_shipping)<>'object' THEN RAISE EXCEPTION 'Enter a shipping address'; END IF;
  IF length(btrim(coalesce(p_shipping->>'full_name',''))) NOT BETWEEN 1 AND 150
     OR length(btrim(coalesce(p_shipping->>'line1',''))) NOT BETWEEN 1 AND 300
     OR length(btrim(coalesce(p_shipping->>'city',''))) NOT BETWEEN 1 AND 150
     OR length(btrim(coalesce(p_shipping->>'country',''))) NOT BETWEEN 1 AND 100
     OR length(coalesce(p_shipping->>'postal_code',''))>20 OR length(coalesce(p_shipping->>'phone',''))>30 THEN
    RAISE EXCEPTION 'Enter a valid name, street address, city and country' USING ERRCODE='22023';
  END IF;
  IF lower(btrim(p_shipping->>'country')) NOT IN ('pakistan','pk') THEN RAISE EXCEPTION 'Delivery is available within Pakistan only'; END IF;
  address:=jsonb_build_object('full_name',btrim(p_shipping->>'full_name'),'line1',btrim(p_shipping->>'line1'),
    'city',btrim(p_shipping->>'city'),'country',btrim(p_shipping->>'country'),
    'postal_code',btrim(coalesce(p_shipping->>'postal_code','')),'phone',btrim(coalesce(p_shipping->>'phone','')));
  IF NOT EXISTS(SELECT 1 FROM public.cart_items ci WHERE ci.user_id=uid) THEN RAISE EXCEPTION 'Your bag is empty'; END IF;
  -- Freeze prices/publication state, then lock variant stock in a consistent order.
  PERFORM p.id FROM public.products p WHERE p.id IN (
    SELECT pv.product_id FROM public.product_variants pv JOIN public.cart_items ci ON ci.variant_id=pv.id WHERE ci.user_id=uid
  ) ORDER BY p.id FOR SHARE;
  PERFORM pv.id FROM public.product_variants pv JOIN public.cart_items ci ON ci.variant_id=pv.id
  WHERE ci.user_id=uid ORDER BY pv.id FOR UPDATE OF pv;
  FOR item IN SELECT ci.quantity,pv.stock,pv.active,p.status FROM public.cart_items ci
    JOIN public.product_variants pv ON pv.id=ci.variant_id JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid
  LOOP
    IF NOT item.active OR item.status<>'published' THEN RAISE EXCEPTION 'A piece in your bag is no longer available'; END IF;
    IF item.stock<item.quantity THEN RAISE EXCEPTION 'Insufficient stock for one or more items' USING ERRCODE='23514'; END IF;
  END LOOP;
  SELECT sum(p.effective_price_cents::bigint*ci.quantity) INTO subtotal FROM public.cart_items ci
  JOIN public.product_variants pv ON pv.id=ci.variant_id JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid;
  INSERT INTO public.orders AS o(user_id,request_id,status,payment_status,subtotal_cents,shipping_cents,total_cents,shipping_address)
  VALUES(uid,p_request_id,'pending','unpaid',subtotal,30000,subtotal+30000,address)
  RETURNING o.id,o.order_number INTO new_order_id,new_order_number;
  INSERT INTO public.order_items(order_id,variant_id,product_name,color,size,image_path,unit_price_cents,quantity)
  SELECT new_order_id,pv.id,p.name,pv.color,pv.size,
    (SELECT im.path FROM public.product_images im WHERE im.product_id=p.id ORDER BY (lower(im.color)=lower(pv.color)) DESC NULLS LAST,im.position LIMIT 1),
    p.effective_price_cents,ci.quantity FROM public.cart_items ci JOIN public.product_variants pv ON pv.id=ci.variant_id
    JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid;
  UPDATE public.product_variants pv SET stock=pv.stock-ci.quantity FROM public.cart_items ci WHERE ci.variant_id=pv.id AND ci.user_id=uid;
  INSERT INTO public.order_status_history(order_id,status) VALUES(new_order_id,'pending');
  DELETE FROM public.cart_items ci WHERE ci.user_id=uid;
  RETURN QUERY SELECT new_order_id,new_order_number,subtotal+30000;
END $function$;


CREATE OR REPLACE FUNCTION public.checkout_order(p_shipping jsonb,p_request_id uuid)
RETURNS TABLE(order_id uuid,order_number bigint,total_cents bigint)
LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE placed record;
BEGIN
 SELECT * INTO placed FROM private.checkout_impl(p_shipping,0,p_request_id);
 IF placed.total_cents>1000000 THEN RAISE EXCEPTION 'Orders above Rs. 10,000 require a 50%% advance via Bank Transfer or EasyPaisa'; END IF;
 RETURN QUERY SELECT placed.order_id,placed.order_number,placed.total_cents;
END $$;
CREATE OR REPLACE FUNCTION public.process_checkout(shipping jsonb,shipping_cents integer DEFAULT 0)
RETURNS TABLE(order_id uuid,order_number bigint,total_cents bigint)
LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE placed record;
BEGIN
 IF coalesce(shipping_cents,0) NOT IN (0,30000) THEN RAISE EXCEPTION 'Delivery is fixed at Rs. 300'; END IF;
 SELECT * INTO placed FROM public.checkout_order(shipping,gen_random_uuid());
 RETURN QUERY SELECT placed.order_id,placed.order_number,placed.total_cents;
END $$;
create or replace function private.checkout_bank_transfer_v2(p_shipping jsonb,p_request_id uuid,p_transaction_id text,p_screenshot_path text,p_contact_number text,p_payment_provider text)
returns table(order_id uuid,order_number bigint,total_cents bigint) language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();settings public.bank_transfer_settings%rowtype;bank jsonb;placed record;phone text:=regexp_replace(trim(coalesce(p_contact_number,'')),'[ ()-]','','g');
begin
 if uid is null then raise exception 'Sign in to checkout' using errcode='28000';end if;
 if p_request_id is null then raise exception 'Checkout request ID is required';end if;
 insert into public.carts(user_id) values(uid) on conflict do nothing;
 perform 1 from public.carts c where c.user_id=uid for update;
 return query select o.id,o.order_number,o.total_cents from public.orders o join public.payment_submissions ps on ps.order_id=o.id where o.user_id=uid and o.request_id=p_request_id and o.payment_method='bank_transfer';
 if found then return;end if;
 if exists(select 1 from public.orders o where o.user_id=uid and o.request_id=p_request_id) then raise exception 'This request belongs to an existing order';end if;
 if phone !~ '^\+?[0-9]{10,15}$' then raise exception 'Enter a valid contact number (10 to 15 digits)';end if;
 if p_payment_provider is null or p_payment_provider not in ('bank_alfalah','jazzcash','easypaisa') then raise exception 'Select Bank Transfer or EasyPaisa';end if;
 if length(trim(coalesce(p_transaction_id,''))) not between 3 and 100 then raise exception 'Enter a valid transaction ID';end if;
 if p_screenshot_path is null or p_screenshot_path not like uid::text||'/'||p_request_id::text||'/%' or not exists(select 1 from storage.objects so where so.bucket_id='payment-receipts' and so.name=p_screenshot_path) then raise exception 'Upload your payment screenshot first';end if;
 select * into settings from public.bank_transfer_settings where id for share;
 if not found then raise exception 'Payment accounts are not configured';end if;
 if p_payment_provider='easypaisa' then
  if not settings.easypaisa_active then raise exception 'EasyPaisa is temporarily unavailable';end if;
  bank:=jsonb_build_object('bank_name','EasyPaisa','account_number',settings.easypaisa_number,'account_title',settings.easypaisa_title,'payment_provider','easypaisa','currency','PKR');
 elsif p_payment_provider='jazzcash' then
  if not settings.jazzcash_active then raise exception 'JazzCash is temporarily unavailable';end if;
  bank:=jsonb_build_object('bank_name','JazzCash','account_number',settings.jazzcash_number,'account_title',settings.jazzcash_title,'payment_provider','jazzcash','currency','PKR');
 else
  if not settings.active then raise exception 'Bank Alfalah is temporarily unavailable';end if;
  bank:=jsonb_build_object('bank_name',settings.bank_name,'account_number',settings.account_number,'account_title',settings.account_title,'iban',settings.iban,'payment_provider','bank_alfalah','currency','PKR');
 end if;
 select * into placed from private.checkout_impl(jsonb_set(p_shipping,'{phone}',to_jsonb(phone)),0,p_request_id);
 if placed.total_cents>1000000 and p_payment_provider='jazzcash' then raise exception 'Advance orders require Bank Transfer or EasyPaisa';end if;
 update public.orders o set payment_method='bank_transfer',currency='PKR',expected_advance_cents=case when placed.total_cents>1000000 then (placed.total_cents+1)/2 else 0 end where o.id=placed.order_id;
 insert into public.payment_submissions(order_id,user_id,transaction_id,screenshot_path,bank_details,contact_number,payment_provider,amount_cents) values(placed.order_id,uid,trim(p_transaction_id),p_screenshot_path,bank,phone,p_payment_provider,case when placed.total_cents>1000000 then (placed.total_cents+1)/2 else placed.total_cents end);
 return query select placed.order_id,placed.order_number,placed.total_cents;
end $$;

create or replace function private.update_order_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare current_status text;method text;payment text;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('pending','confirmed','processing','shipped','delivered','cancelled') then raise exception 'Invalid status';end if;
 select o.status,o.payment_method,o.payment_status into current_status,method,payment from public.orders o where o.id=p_order_id for update;
 if not found then raise exception 'Order not found';end if;
 if current_status=p_status then return;end if;
 if current_status in ('cancelled','delivered') then raise exception 'This order is already closed';end if;
 if method='bank_transfer' and p_status in ('confirmed','processing','shipped','delivered') and payment<>'paid' and not exists(select 1 from public.orders o join public.payment_submissions ps on ps.order_id=o.id where o.id=p_order_id and ps.status='approved' and o.expected_advance_cents>0 and o.advance_paid_cents>=o.expected_advance_cents) then raise exception 'Verify and approve the payment in Payments before confirming this order';end if;
 if p_status='cancelled' then
  if current_status='shipped' then raise exception 'A shipped order cannot be cancelled; contact the customer about a return';end if;
  perform pv.id from public.product_variants pv where pv.id in(select oi.variant_id from public.order_items oi where oi.order_id=p_order_id) order by pv.id for update;
  update public.product_variants pv set stock=pv.stock+x.quantity from(select oi.variant_id,sum(oi.quantity)::integer as quantity from public.order_items oi where oi.order_id=p_order_id group by oi.variant_id)x where pv.id=x.variant_id;
 elsif array_position(array['pending','confirmed','processing','shipped','delivered'],p_status)<=array_position(array['pending','confirmed','processing','shipped','delivered'],current_status) then raise exception 'Order status can only move forward';end if;
 update public.orders o set status=p_status where o.id=p_order_id;
 insert into public.order_status_history(order_id,status) values(p_order_id,p_status);
end $$;

create or replace function private.review_bank_payment(p_payment_id uuid,p_status text,p_note text)
returns void language plpgsql security definer set search_path='' as $$
declare submission public.payment_submissions%rowtype;ord public.orders%rowtype;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('approved','rejected') or length(coalesce(p_note,''))>1000 then raise exception 'Invalid review';end if;
 select o.* into ord from public.orders o where o.id=(select ps.order_id from public.payment_submissions ps where ps.id=p_payment_id) for update;
 select * into submission from public.payment_submissions where id=p_payment_id for update;
 if submission.id is null then raise exception 'Payment not found';end if;
 if submission.status<>'pending' then raise exception 'This payment has already been reviewed';end if;
 if ord.status in ('cancelled','delivered') or ord.payment_status<>'unpaid' then raise exception 'This order cannot receive a payment review';end if;
 if p_status='rejected' and length(trim(coalesce(p_note,'')))=0 then raise exception 'Explain why the payment was rejected';end if;
 update public.payment_submissions set status=p_status,review_note=trim(coalesce(p_note,'')),reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=p_payment_id;
 if p_status='approved' then
  update public.orders set advance_paid_cents=coalesce(submission.amount_cents,ord.total_cents) where id=ord.id;
  if coalesce(submission.amount_cents,ord.total_cents)>=ord.total_cents then perform private.record_payment_status(submission.order_id,'paid');end if;
  if ord.status='pending' then perform private.update_order_status(ord.id,'confirmed');end if;
 end if;
end $$;

create or replace function private.record_payment_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare old_status text;order_status text;method text;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('unpaid','paid','refunded') then raise exception 'Invalid payment status';end if;
 select o.payment_status,o.status,o.payment_method into old_status,order_status,method from public.orders o where o.id=p_order_id for update;
 if not found then raise exception 'Order not found';end if;
 if old_status=p_status then return;end if;
 if p_status='paid' and order_status='cancelled' then raise exception 'Cannot mark a cancelled order as paid';end if;
 if p_status='paid' and method='bank_transfer' and not exists(select 1 from public.payment_submissions ps where ps.order_id=p_order_id and ps.status='approved') then raise exception 'Approve the payment proof in Payments first';end if;
 if p_status='refunded' and old_status<>'paid' then raise exception 'Only a paid order can be marked refunded';end if;
 if p_status='unpaid' and old_status='refunded' then raise exception 'A refunded payment cannot be marked unpaid';end if;
 update public.orders o set payment_status=p_status,advance_paid_cents=case when p_status='paid' then total_cents else advance_paid_cents end where o.id=p_order_id;
 insert into public.admin_notes(order_id,note) values(p_order_id,'Payment recorded as '||p_status||' by admin '||auth.uid()::text);
end $$;

REVOKE ALL ON FUNCTION private.checkout_impl(jsonb,integer,uuid),public.checkout_order(jsonb,uuid),public.process_checkout(jsonb,integer),private.checkout_bank_transfer_v2(jsonb,uuid,text,text,text,text),private.review_bank_payment(uuid,text,text),private.update_order_status(uuid,text),private.record_payment_status(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.checkout_impl(jsonb,integer,uuid),public.checkout_order(jsonb,uuid),public.process_checkout(jsonb,integer),private.checkout_bank_transfer_v2(jsonb,uuid,text,text,text,text),private.review_bank_payment(uuid,text,text),private.update_order_status(uuid,text),private.record_payment_status(uuid,text) TO authenticated;
COMMIT;
