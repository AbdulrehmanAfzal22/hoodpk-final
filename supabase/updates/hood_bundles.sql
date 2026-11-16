BEGIN;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_bundle boolean NOT NULL DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS bundle_version integer NOT NULL DEFAULT 1;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS bundle_selection jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS bundle_version integer;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS bundle_selection jsonb NOT NULL DEFAULT '[]'::jsonb;
CREATE TABLE IF NOT EXISTS public.hood_bundle_items(
 bundle_product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
 product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
 position integer NOT NULL,PRIMARY KEY(bundle_product_id,product_id),CHECK(bundle_product_id<>product_id));
CREATE INDEX IF NOT EXISTS hood_bundle_items_product_idx ON public.hood_bundle_items(product_id);
ALTER TABLE public.hood_bundle_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY hood_bundle_read ON public.hood_bundle_items FOR SELECT TO anon,authenticated USING(EXISTS(SELECT 1 FROM public.products p WHERE p.id=bundle_product_id AND p.storefront='hood' AND (p.status='published' OR private.is_admin())));
GRANT SELECT ON public.hood_bundle_items TO anon,authenticated;
GRANT ALL ON public.hood_bundle_items TO service_role;
CREATE OR REPLACE FUNCTION private.hood_save_bundle(p_id uuid,p_name text,p_description text,p_price integer,p_products uuid[],p_status text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE pid uuid:=coalesce(p_id,gen_random_uuid());cid uuid; n integer;
BEGIN
 IF NOT private.is_admin() THEN RAISE EXCEPTION 'Admin access required';END IF;
 IF length(trim(p_name)) NOT BETWEEN 1 AND 200 OR length(coalesce(p_description,''))>8000 OR p_price IS NULL OR p_price<=0 OR p_price>100000000 OR p_status NOT IN ('draft','published','archived') THEN RAISE EXCEPTION 'Enter a name, valid fixed price and status';END IF;
 SELECT count(DISTINCT x) INTO n FROM unnest(p_products)x;
 IF n<2 OR n<>cardinality(p_products) THEN RAISE EXCEPTION 'Select at least two different products';END IF;
 IF (SELECT count(*) FROM public.products WHERE id=ANY(p_products) AND storefront='hood' AND NOT is_bundle AND NOT enquiry_only AND status='published')<>n THEN RAISE EXCEPTION 'Choose published, priced products; bundles cannot contain other bundles';END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_products)x WHERE NOT EXISTS(SELECT 1 FROM public.product_variants WHERE product_id=x AND active AND stock>0)) THEN RAISE EXCEPTION 'Every included product needs at least one in-stock option';END IF;
 SELECT id INTO cid FROM public.categories WHERE storefront='hood' AND slug='hood-combo-deals-bundles';
 IF cid IS NULL THEN RAISE EXCEPTION 'Combo category is missing';END IF;
 IF p_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.products WHERE id=pid AND storefront='hood' AND is_bundle) THEN RAISE EXCEPTION 'Bundle not found';END IF;
 INSERT INTO public.products(id,category_id,name,description,price_cents,status,featured,department,storefront,currency,enquiry_only,is_bundle)
 VALUES(pid,cid,trim(p_name),coalesce(p_description,''),p_price,p_status,false,'unisex','hood','PKR',false,true)
 ON CONFLICT(id) DO UPDATE SET name=excluded.name,description=excluded.description,price_cents=excluded.price_cents,sale_price_cents=null,status=excluded.status,bundle_version=public.products.bundle_version+1;
 DELETE FROM public.hood_bundle_items WHERE bundle_product_id=pid;
 INSERT INTO public.hood_bundle_items SELECT pid,x,ord::integer FROM unnest(p_products) WITH ORDINALITY t(x,ord);
 -- This is a virtual pack option, not independently stocked inventory.
 INSERT INTO public.product_variants(product_id,color,color_hex,size,stock,active) VALUES(pid,'Choose each item','#111111','Bundle',99,true) ON CONFLICT(product_id,color,size) DO UPDATE SET active=true;
 RETURN pid;
END $$;
REVOKE ALL ON FUNCTION private.hood_save_bundle(uuid,text,text,integer,uuid[],text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.hood_save_bundle(uuid,text,text,integer,uuid[],text) TO authenticated;
CREATE OR REPLACE FUNCTION public.hood_save_bundle(p_id uuid,p_name text,p_description text,p_price integer,p_products uuid[],p_status text)
RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_save_bundle($1,$2,$3,$4,$5,$6)$$;
REVOKE ALL ON FUNCTION public.hood_save_bundle(uuid,text,text,integer,uuid[],text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.hood_save_bundle(uuid,text,text,integer,uuid[],text) TO authenticated;
CREATE OR REPLACE FUNCTION private.hood_validate_bundle(pid uuid,selection jsonb,qty integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; expected integer;
BEGIN
 IF qty IS NULL OR qty NOT BETWEEN 1 AND 99 OR jsonb_typeof(selection)<>'array' THEN RAISE EXCEPTION 'Choose valid bundle options and quantity';END IF;
 SELECT count(*) INTO expected FROM public.hood_bundle_items WHERE bundle_product_id=pid;
 IF expected<2 OR jsonb_array_length(selection)<>expected THEN RAISE EXCEPTION 'Choose a colour and size for every bundle item';END IF;
 IF (SELECT count(DISTINCT x->>'product_id') FROM jsonb_array_elements(selection)x)<>expected THEN RAISE EXCEPTION 'Choose each bundle product once';END IF;
 SELECT jsonb_agg(jsonb_build_object('product_id',p.id,'variant_id',v.id,'product_name',p.name,'color',v.color,'size',v.size,'image_path',(SELECT im.path FROM public.product_images im WHERE im.product_id=p.id ORDER BY (im.color=v.color) DESC NULLS LAST,im.position LIMIT 1)) ORDER BY b.position)
 INTO result FROM public.hood_bundle_items b JOIN public.products p ON p.id=b.product_id
 JOIN jsonb_array_elements(selection)x ON (x->>'product_id')::uuid=p.id
 JOIN public.product_variants v ON v.id=(x->>'variant_id')::uuid AND v.product_id=p.id
 WHERE b.bundle_product_id=pid AND p.storefront='hood' AND p.status='published' AND NOT p.enquiry_only AND NOT p.is_bundle AND v.active AND v.stock>=qty;
 IF coalesce(jsonb_array_length(result),0)<>expected THEN RAISE EXCEPTION 'A bundle option is unavailable. Select an in-stock colour and size for each item';END IF;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.hood_validate_bundle(uuid,jsonb,integer) FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION private.hood_bundle_cart_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.products;
BEGIN
 SELECT x.* INTO p FROM public.products x JOIN public.product_variants v ON v.product_id=x.id WHERE v.id=NEW.variant_id;
 IF p.is_bundle THEN
  IF NEW.bundle_version IS DISTINCT FROM p.bundle_version THEN RAISE EXCEPTION 'This bundle has changed. Remove it from your cart and choose its items again';END IF;
  NEW.bundle_selection:=private.hood_validate_bundle(p.id,NEW.bundle_selection,NEW.quantity);
 ELSE
  NEW.bundle_selection:='[]';NEW.bundle_version:=NULL;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.hood_bundle_cart_guard() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER hood_bundle_cart_guard BEFORE INSERT OR UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION private.hood_bundle_cart_guard();
CREATE OR REPLACE FUNCTION private.hood_add_bundle(pid uuid,selection jsonb,qty integer,note text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE uid uuid:=auth.uid(); vid uuid; version integer; previous public.cart_items; clean jsonb;
BEGIN
 IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required';END IF;
 IF length(coalesce(note,''))>2000 THEN RAISE EXCEPTION 'Notes must be 2000 characters or fewer';END IF;
 INSERT INTO public.carts(user_id) VALUES(uid) ON CONFLICT DO NOTHING;
 PERFORM 1 FROM public.carts WHERE user_id=uid FOR UPDATE;
 SELECT p.bundle_version,v.id INTO version,vid FROM public.products p JOIN public.product_variants v ON v.product_id=p.id AND v.active WHERE p.id=pid AND p.storefront='hood' AND p.is_bundle AND p.status='published' LIMIT 1;
 IF vid IS NULL THEN RAISE EXCEPTION 'Bundle is no longer available';END IF;
 clean:=private.hood_validate_bundle(pid,selection,qty);
 SELECT * INTO previous FROM public.cart_items WHERE user_id=uid AND variant_id=vid FOR UPDATE;
 IF FOUND THEN
  IF previous.bundle_selection<>clean OR previous.customisation_note<>trim(coalesce(note,'')) OR previous.bundle_version<>version THEN RAISE EXCEPTION 'This bundle is already in your cart with different choices. Remove it first to change the selection';END IF;
  PERFORM private.hood_validate_bundle(pid,clean,previous.quantity+qty);
 END IF;
 INSERT INTO public.cart_items(user_id,variant_id,quantity,customisation_note,bundle_selection,bundle_version) VALUES(uid,vid,qty,trim(coalesce(note,'')),clean,version)
 ON CONFLICT(user_id,variant_id) DO UPDATE SET quantity=public.cart_items.quantity+excluded.quantity;
END $$;
REVOKE ALL ON FUNCTION private.hood_add_bundle(uuid,jsonb,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.hood_add_bundle(uuid,jsonb,integer,text) TO authenticated;
CREATE OR REPLACE FUNCTION public.hood_add_bundle_to_cart(p_product_id uuid,p_selections jsonb,p_quantity integer,p_note text DEFAULT '')
RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_add_bundle($1,$2,$3,$4)$$;
REVOKE ALL ON FUNCTION public.hood_add_bundle_to_cart(uuid,jsonb,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.hood_add_bundle_to_cart(uuid,jsonb,integer,text) TO authenticated;
CREATE OR REPLACE FUNCTION private.hood_snapshot_bundle()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE uid uuid; store text; pid uuid; ci public.cart_items; choice jsonb; available integer; normal_demand integer;
BEGIN
 SELECT user_id,storefront INTO uid,store FROM public.orders WHERE id=NEW.order_id;
 IF store<>'hood' THEN RETURN NEW;END IF;
 SELECT product_id INTO pid FROM public.product_variants WHERE id=NEW.variant_id;
 IF NOT coalesce((SELECT is_bundle FROM public.products WHERE id=pid),false) THEN RETURN NEW;END IF;
 SELECT * INTO ci FROM public.cart_items WHERE user_id=uid AND variant_id=NEW.variant_id;
 IF ci.bundle_version IS DISTINCT FROM (SELECT bundle_version FROM public.products WHERE id=pid) THEN RAISE EXCEPTION 'Bundle has changed. Select its items again';END IF;
 NEW.bundle_selection:=private.hood_validate_bundle(pid,ci.bundle_selection,NEW.quantity);
 FOR choice IN SELECT * FROM jsonb_array_elements(NEW.bundle_selection) LOOP
  SELECT stock INTO available FROM public.product_variants WHERE id=(choice->>'variant_id')::uuid FOR UPDATE;
  SELECT coalesce(sum(quantity),0)::integer INTO normal_demand FROM public.cart_items WHERE user_id=uid AND variant_id=(choice->>'variant_id')::uuid;
  IF available<NEW.quantity+normal_demand THEN RAISE EXCEPTION 'Insufficient stock for bundle item %',choice->>'product_name';END IF;
  UPDATE public.product_variants SET stock=stock-NEW.quantity WHERE id=(choice->>'variant_id')::uuid;
 END LOOP;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.hood_snapshot_bundle() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER hood_snapshot_bundle BEFORE INSERT ON public.order_items FOR EACH ROW EXECUTE FUNCTION private.hood_snapshot_bundle();
CREATE OR REPLACE FUNCTION private.hood_restore_bundle_stock()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE line record;choice jsonb;
BEGIN
 IF NEW.storefront='hood' AND NEW.status='cancelled' AND OLD.status<>'cancelled' THEN
  FOR line IN SELECT quantity,bundle_selection FROM public.order_items WHERE order_id=NEW.id AND jsonb_array_length(bundle_selection)>0 LOOP
   FOR choice IN SELECT * FROM jsonb_array_elements(line.bundle_selection) LOOP
    UPDATE public.product_variants SET stock=stock+line.quantity WHERE id=(choice->>'variant_id')::uuid;
   END LOOP;
  END LOOP;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.hood_restore_bundle_stock() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER hood_restore_bundle_stock AFTER UPDATE OF status ON public.orders FOR EACH ROW EXECUTE FUNCTION private.hood_restore_bundle_stock();

CREATE OR REPLACE FUNCTION private.hood_checkout_impl(p_shipping jsonb, p_shipping_cents integer, p_request_id uuid)
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
  RETURN QUERY SELECT o.id,o.order_number,o.total_cents FROM public.orders o WHERE o.user_id=uid AND o.request_id=p_request_id AND o.storefront='hood';
  IF FOUND THEN RETURN; END IF;

  IF p_shipping IS NULL OR jsonb_typeof(p_shipping)<>'object' THEN RAISE EXCEPTION 'Enter a shipping address'; END IF;
  IF length(btrim(coalesce(p_shipping->>'full_name',''))) NOT BETWEEN 1 AND 150
     OR length(btrim(coalesce(p_shipping->>'line1',''))) NOT BETWEEN 1 AND 300
     OR length(btrim(coalesce(p_shipping->>'city',''))) NOT BETWEEN 1 AND 150
     OR length(btrim(coalesce(p_shipping->>'country',''))) NOT BETWEEN 1 AND 100
     OR length(coalesce(p_shipping->>'postal_code',''))>20 OR length(coalesce(p_shipping->>'phone',''))>30 THEN
    RAISE EXCEPTION 'Enter a valid name, street address, city and country' USING ERRCODE='22023';
  END IF;
  IF lower(btrim(p_shipping->>'country')) NOT IN ('pakistan','pk') THEN RAISE EXCEPTION 'Delivery is available within Pakistan only';END IF;
  IF regexp_replace(coalesce(p_shipping->>'phone',''),'[ ()-]','','g') !~ '^\+?[0-9]{10,15}$' THEN RAISE EXCEPTION 'Enter a valid contact number';END IF;
  address:=jsonb_build_object('full_name',btrim(p_shipping->>'full_name'),'line1',btrim(p_shipping->>'line1'),
    'city',btrim(p_shipping->>'city'),'country',btrim(p_shipping->>'country'),
    'postal_code',btrim(coalesce(p_shipping->>'postal_code','')),'phone',btrim(coalesce(p_shipping->>'phone','')));
  IF NOT EXISTS(SELECT 1 FROM public.cart_items ci JOIN public.product_variants v ON v.id=ci.variant_id JOIN public.products p ON p.id=v.product_id WHERE ci.user_id=uid AND p.storefront='hood') THEN RAISE EXCEPTION 'Your bag is empty'; END IF;
  -- Freeze prices/publication state, then lock variant stock in a consistent order.
  PERFORM p.id FROM public.products p WHERE p.id IN (
    SELECT pv.product_id FROM public.product_variants pv JOIN public.cart_items ci ON ci.variant_id=pv.id WHERE ci.user_id=uid
    UNION SELECT (x->>'product_id')::uuid FROM public.cart_items ci CROSS JOIN LATERAL jsonb_array_elements(ci.bundle_selection)x WHERE ci.user_id=uid
  ) AND p.storefront='hood' ORDER BY p.id FOR SHARE;
  PERFORM pv.id FROM public.product_variants pv WHERE pv.id IN (
    SELECT ci.variant_id FROM public.cart_items ci WHERE ci.user_id=uid
    UNION SELECT (x->>'variant_id')::uuid FROM public.cart_items ci CROSS JOIN LATERAL jsonb_array_elements(ci.bundle_selection)x WHERE ci.user_id=uid
  ) ORDER BY pv.id FOR UPDATE;
  FOR item IN SELECT ci.quantity,pv.stock,pv.active,p.status,p.enquiry_only,p.effective_price_cents FROM public.cart_items ci
    JOIN public.product_variants pv ON pv.id=ci.variant_id JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid AND p.storefront='hood'
  LOOP
    IF item.enquiry_only OR item.effective_price_cents IS NULL THEN RAISE EXCEPTION 'Enquiry products cannot be checked out';END IF;
    IF NOT item.active OR item.status<>'published' THEN RAISE EXCEPTION 'A piece in your bag is no longer available'; END IF;
    IF item.stock<item.quantity THEN RAISE EXCEPTION 'Insufficient stock for one or more items' USING ERRCODE='23514'; END IF;
  END LOOP;
  SELECT sum(p.effective_price_cents::bigint*ci.quantity) INTO subtotal FROM public.cart_items ci
  JOIN public.product_variants pv ON pv.id=ci.variant_id JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid AND p.storefront='hood';
  INSERT INTO public.orders AS o(user_id,request_id,status,payment_status,subtotal_cents,shipping_cents,total_cents,shipping_address,currency,storefront)
  VALUES(uid,p_request_id,'pending','unpaid',subtotal,30000,subtotal+30000,address,'PKR','hood')
  RETURNING o.id,o.order_number INTO new_order_id,new_order_number;
  INSERT INTO public.order_items(order_id,variant_id,product_name,color,size,image_path,unit_price_cents,quantity)
  SELECT new_order_id,pv.id,p.name,pv.color,pv.size,
    (SELECT im.path FROM public.product_images im WHERE im.product_id=p.id ORDER BY (lower(im.color)=lower(pv.color)) DESC NULLS LAST,im.position LIMIT 1),
    p.effective_price_cents,ci.quantity FROM public.cart_items ci JOIN public.product_variants pv ON pv.id=ci.variant_id
    JOIN public.products p ON p.id=pv.product_id WHERE ci.user_id=uid AND p.storefront='hood';
  UPDATE public.product_variants pv SET stock=pv.stock-ci.quantity FROM public.cart_items ci WHERE ci.variant_id=pv.id AND ci.user_id=uid AND EXISTS(SELECT 1 FROM public.products p WHERE p.id=pv.product_id AND p.storefront='hood' AND NOT p.is_bundle);
  INSERT INTO public.order_status_history(order_id,status) VALUES(new_order_id,'pending');
  DELETE FROM public.cart_items ci WHERE ci.user_id=uid AND EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=ci.variant_id AND p.storefront='hood');
  RETURN QUERY SELECT new_order_id,new_order_number,subtotal+30000;
END $function$;
NOTIFY pgrst,'reload schema';
COMMIT;
