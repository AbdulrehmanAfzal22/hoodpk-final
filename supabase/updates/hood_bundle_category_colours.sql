BEGIN;
CREATE OR REPLACE FUNCTION private.hood_validate_bundle(pid uuid,selection jsonb,qty integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; expected integer;
BEGIN
 IF qty IS NULL OR qty NOT BETWEEN 1 AND 99 OR jsonb_typeof(selection)<>'array' THEN RAISE EXCEPTION 'Choose valid bundle options and quantity';END IF;
 SELECT count(*) INTO expected FROM public.hood_bundle_items WHERE bundle_product_id=pid;
 IF expected<2 OR jsonb_array_length(selection)<>expected THEN RAISE EXCEPTION 'Choose a colour and size for every bundle item';END IF;
 IF (SELECT count(DISTINCT coalesce(x->>'slot_product_id',x->>'product_id')) FROM jsonb_array_elements(selection)x)<>expected THEN RAISE EXCEPTION 'Choose each bundle slot once';END IF;
 SELECT jsonb_agg(jsonb_build_object('slot_product_id',b.product_id,'product_id',p.id,'variant_id',v.id,'product_name',p.name,'color',v.color,'size',v.size,'image_path',(SELECT im.path FROM public.product_images im WHERE im.product_id=p.id ORDER BY (im.color=v.color) DESC NULLS LAST,im.position LIMIT 1)) ORDER BY b.position)
 INTO result FROM public.hood_bundle_items b JOIN public.products seed ON seed.id=b.product_id JOIN public.categories category ON category.id=seed.category_id
 JOIN jsonb_array_elements(selection)x ON coalesce(x->>'slot_product_id',x->>'product_id')::uuid=b.product_id
 JOIN public.products p ON p.id=(x->>'product_id')::uuid
 JOIN public.product_variants v ON v.id=(x->>'variant_id')::uuid AND v.product_id=p.id
 WHERE b.bundle_product_id=pid AND p.storefront='hood' AND seed.storefront='hood' AND p.status='published' AND NOT p.enquiry_only AND NOT p.is_bundle AND v.active AND v.stock>=qty
 AND (p.id=seed.id OR (p.category_id=seed.category_id AND category.storefront='hood' AND category.slug IN('hood-plain-hoodies','hood-sweatshirts','hood-zipper-hoodies')));
 IF coalesce(jsonb_array_length(result),0)<>expected THEN RAISE EXCEPTION 'A bundle option is unavailable. Choose an in-stock colour and size from the correct category';END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(result)x JOIN public.product_variants v ON v.id=(x->>'variant_id')::uuid GROUP BY v.id,v.stock HAVING v.stock<count(*)*qty) THEN RAISE EXCEPTION 'Insufficient stock for repeated bundle selections';END IF;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.hood_validate_bundle(uuid,jsonb,integer) FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
