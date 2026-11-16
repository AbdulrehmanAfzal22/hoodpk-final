BEGIN;
ALTER TABLE public.cart_items ADD COLUMN IF NOT EXISTS customisation_note text NOT NULL DEFAULT '' CHECK(length(customisation_note)<=2000);
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS customisation_note text NOT NULL DEFAULT '' CHECK(length(customisation_note)<=2000);
CREATE OR REPLACE FUNCTION private.hood_add_to_cart_with_note(p_variant_id uuid,p_quantity integer,p_note text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE uid uuid:=auth.uid(); note text:=trim(coalesce(p_note,'')); previous text;
BEGIN
 IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000'; END IF;
 IF length(note)>2000 THEN RAISE EXCEPTION 'Customisation notes must be 2000 characters or fewer'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=p_variant_id AND p.storefront='hood') THEN RAISE EXCEPTION 'HOOD product not found'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(uid::text||p_variant_id::text,0));
 SELECT ci.customisation_note INTO previous FROM public.cart_items ci WHERE ci.user_id=uid AND ci.variant_id=p_variant_id FOR UPDATE;
 IF FOUND AND previous<>note THEN RAISE EXCEPTION 'This colour and size is already in your cart with a different note. Remove that cart item first to change the customisation.'; END IF;
 PERFORM private.hood_change_cart(p_variant_id,p_quantity,'add');
 UPDATE public.cart_items SET customisation_note=note WHERE user_id=uid AND variant_id=p_variant_id;
END $$;
REVOKE ALL ON FUNCTION private.hood_add_to_cart_with_note(uuid,integer,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.hood_add_to_cart_with_note(uuid,integer,text) TO authenticated;
CREATE OR REPLACE FUNCTION public.hood_add_to_cart_with_note(p_variant_id uuid,p_quantity integer,p_note text DEFAULT '')
RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_add_to_cart_with_note($1,$2,$3)$$;
REVOKE ALL ON FUNCTION public.hood_add_to_cart_with_note(uuid,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.hood_add_to_cart_with_note(uuid,integer,text) TO authenticated;
CREATE OR REPLACE FUNCTION private.hood_snapshot_item_note()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE uid uuid; store text;
BEGIN
 SELECT user_id,storefront INTO uid,store FROM public.orders WHERE id=NEW.order_id;
 IF store='hood' THEN
  SELECT coalesce(ci.customisation_note,'') INTO NEW.customisation_note FROM public.cart_items ci WHERE ci.user_id=uid AND ci.variant_id=NEW.variant_id;
  NEW.customisation_note:=coalesce(NEW.customisation_note,'');
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.hood_snapshot_item_note() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS hood_snapshot_item_note ON public.order_items;
CREATE TRIGGER hood_snapshot_item_note BEFORE INSERT ON public.order_items FOR EACH ROW EXECUTE FUNCTION private.hood_snapshot_item_note();
NOTIFY pgrst,'reload schema';
COMMIT;
