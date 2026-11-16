-- Full HOOD backend upgrade against the inspected cloth-web schema.
-- Existing Legacy/Sunnah records, functions and checkout defaults are preserved.
BEGIN;

-- Optional persisted catalogue import. Deploy the accompanying assets/code together.
-- No old product, customer or order rows are deleted. HOOD uses its own storefront.

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS storefront text NOT NULL DEFAULT 'legacy';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS storefront text NOT NULL DEFAULT 'legacy';
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_storefront_check;
ALTER TABLE public.products ADD CONSTRAINT products_storefront_check CHECK(storefront IN ('legacy','sunnah','hood'));
ALTER TABLE public.categories DROP CONSTRAINT IF EXISTS categories_storefront_check;
ALTER TABLE public.categories ADD CONSTRAINT categories_storefront_check CHECK(storefront IN ('legacy','sunnah','hood'));
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS enquiry_only boolean NOT NULL DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS inquiry_colours jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS sale_price_cents integer;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS effective_price_cents integer GENERATED ALWAYS AS (coalesce(sale_price_cents,price_cents)) STORED;
ALTER TABLE public.products ALTER COLUMN price_cents DROP NOT NULL;
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_price_cents_check;
ALTER TABLE public.products ADD CONSTRAINT products_price_cents_check CHECK ((enquiry_only AND price_cents IS NULL AND sale_price_cents IS NULL) OR (NOT enquiry_only AND price_cents IS NOT NULL AND price_cents>0 AND price_cents<=100000000));
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS currency text NOT NULL DEFAULT 'PKR';
CREATE OR REPLACE FUNCTION private.guard_hood_enquiry_cart()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN
 IF EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=NEW.variant_id AND p.enquiry_only) THEN
  RAISE EXCEPTION 'This listing is enquiry-only. Confirm pricing and availability through WhatsApp.';
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.guard_hood_enquiry_cart() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS hood_enquiry_cart_guard ON public.cart_items;
CREATE TRIGGER hood_enquiry_cart_guard BEFORE INSERT OR UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION private.guard_hood_enquiry_cart();
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('89c781c1-9e59-5728-8a60-a78a36609101','THE HOOD.PK · Customised Hoodies','hood-customised-hoodies','',false,true,1,NULL,'Customised Hoodies','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('4e2ba1c5-97ef-5f96-9a9a-bb473b87467e','THE HOOD.PK · Printed','hood-printed','',false,true,2,'03b529c4-add4-5061-8d59-2518e9d84fbc/photo-01.jpeg','Printed','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('7ff1fde4-fa98-5f02-94e0-fded298cc23a','THE HOOD.PK · Plain Hoodies','hood-plain-hoodies','',false,true,3,'5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-01.jpeg','Plain Hoodies','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('9f8e11d0-2878-57ce-ad49-9384afa31399','THE HOOD.PK · Zipper Hoodies','hood-zipper-hoodies','',false,true,4,NULL,'Zipper Hoodies','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('1370039f-fc2a-5066-b9b3-cda1bb46c590','THE HOOD.PK · Sweatshirts','hood-sweatshirts','',false,true,5,NULL,'Sweatshirts','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('b04c2f2f-485a-534f-a6e8-11ed43cf7708','THE HOOD.PK · T-Shirts','hood-t-shirts','',false,true,6,NULL,'T-Shirts','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.categories(id,name,slug,description,is_accessory,is_active,display_order,image_path,image_alt,storefront) VALUES ('9dadd04f-4f06-582a-a084-35098d2fafee','THE HOOD.PK · Combo Deals / Bundles','hood-combo-deals-bundles','',false,true,7,'f85b681f-13c3-54db-aeee-849641cd500f/photo-01.jpeg','Combo Deals / Bundles','hood') ON CONFLICT(id) DO UPDATE SET name=excluded.name,slug=excluded.slug,is_active=true,image_path=excluded.image_path,image_alt=excluded.image_alt,storefront='hood';
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('f85b681f-13c3-54db-aeee-849641cd500f','9dadd04f-4f06-582a-a084-35098d2fafee','With Love Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('f5b9e332-d3aa-5d78-b15c-6fe98884bf3e','f85b681f-13c3-54db-aeee-849641cd500f','f85b681f-13c3-54db-aeee-849641cd500f/photo-01.jpeg',NULL,'With Love Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('ef70d7aa-ec9b-5738-b759-75cd66b247fb','9dadd04f-4f06-582a-a084-35098d2fafee','Never Forget Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('ca036ae2-d452-5fba-926a-4334a89225e9','ef70d7aa-ec9b-5738-b759-75cd66b247fb','ef70d7aa-ec9b-5738-b759-75cd66b247fb/photo-01.jpeg',NULL,'Never Forget Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('8fdd5f05-7054-530f-a2b1-ef4ac46464b6','9dadd04f-4f06-582a-a084-35098d2fafee','Statement Print Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('c4b623bb-51c5-5c4b-a531-ead8aed8d3f7','8fdd5f05-7054-530f-a2b1-ef4ac46464b6','8fdd5f05-7054-530f-a2b1-ef4ac46464b6/photo-01.jpeg',NULL,'Statement Print Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('31d639a0-058a-5bc8-843a-6221d353d184','9dadd04f-4f06-582a-a084-35098d2fafee','It Is What It Is Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('5f3f9d42-660f-5d8e-a48c-5b73692eebde','31d639a0-058a-5bc8-843a-6221d353d184','31d639a0-058a-5bc8-843a-6221d353d184/photo-01.jpeg',NULL,'It Is What It Is Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('b21de1dc-6c15-5d14-bc3b-d7f4f5576d98','9dadd04f-4f06-582a-a084-35098d2fafee','Off Duty Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('3a022a2e-ba1a-51dd-8728-6c139eed2a53','b21de1dc-6c15-5d14-bc3b-d7f4f5576d98','b21de1dc-6c15-5d14-bc3b-d7f4f5576d98/photo-01.jpeg',NULL,'Off Duty Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('ddbb2e6f-8e5a-53a6-817d-1fd86ddf6da2','9dadd04f-4f06-582a-a084-35098d2fafee','You Talk Too Much Bundle','Bundle reference supplied for THE HOOD.PK. Contact us on WhatsApp to confirm the included items, available colours, sizes, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('2598bb40-8634-5a1d-a176-19644c959e5f','ddbb2e6f-8e5a-53a6-817d-1fd86ddf6da2','ddbb2e6f-8e5a-53a6-817d-1fd86ddf6da2/photo-01.jpeg',NULL,'You Talk Too Much Bundle',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('5a0610d1-b8cc-5e2e-b931-878969ab8841','7ff1fde4-fa98-5f02-94e0-fded298cc23a','Plain Hoodie — 14 Colours','Choose from the fourteen supplied hoodie colours and enquire on WhatsApp. Please confirm sizes, pricing and availability with our team before ordering.','',NULL,'published',false,'unisex','hood','PKR',true,'[{"color": "Brown", "color_hex": "#70432c"}, {"color": "Orange", "color_hex": "#f0641a"}, {"color": "Yellow", "color_hex": "#f5cd12"}, {"color": "Purple", "color_hex": "#653990"}, {"color": "Red", "color_hex": "#d91b2b"}, {"color": "Hot Pink", "color_hex": "#e81777"}, {"color": "Lilac", "color_hex": "#af88cf"}, {"color": "Navy Green", "color_hex": "#123d2d"}, {"color": "Baby Blue", "color_hex": "#8fb5d8"}, {"color": "White", "color_hex": "#f4f1eb"}, {"color": "Light grey", "color_hex": "#c4c5cb"}, {"color": "Black", "color_hex": "#111111"}, {"color": "Baby Pink", "color_hex": "#f3b8d0"}, {"color": "Navy Blue", "color_hex": "#16233e"}]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('649c885a-cb8e-5d59-9e74-816fdea5bd5e','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-01.jpeg','Brown','Plain Hoodie — 14 Colours — Brown',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('36fec35a-5cb8-5886-91b3-d1457723a8f8','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-02.jpeg','Orange','Plain Hoodie — 14 Colours — Orange',1) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('a479c13e-fc61-5db4-bd27-b741de01ed21','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-03.jpeg','Yellow','Plain Hoodie — 14 Colours — Yellow',2) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('53f8c56d-c650-5ff8-8feb-dff27de60881','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-04.jpeg','Purple','Plain Hoodie — 14 Colours — Purple',3) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('7f3531e8-6ef9-5df1-b4a9-313a9454e8bd','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-05.jpeg','Red','Plain Hoodie — 14 Colours — Red',4) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('6d0a4a8e-e8ad-57d5-8ca3-417101fee91c','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-06.jpeg','Hot Pink','Plain Hoodie — 14 Colours — Hot Pink',5) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('1620b321-00c2-5c4f-a024-b460bb2f5e1a','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-07.jpeg','Lilac','Plain Hoodie — 14 Colours — Lilac',6) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('e0f49135-9f99-5a9f-93b7-3aee723ee07e','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-08.jpeg','Navy Green','Plain Hoodie — 14 Colours — Navy Green',7) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('7ab94db3-8cdd-5ab8-b9f4-9273b0b5d7df','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-09.jpeg','Baby Blue','Plain Hoodie — 14 Colours — Baby Blue',8) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('85659acb-e39d-56f7-92f5-78b13492cd15','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-10.jpeg','White','Plain Hoodie — 14 Colours — White',9) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('0abf1384-d7a8-59f4-8ee8-32f8da51b0da','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-11.jpeg','Light grey','Plain Hoodie — 14 Colours — Light grey',10) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('2d97a2f2-94f1-50a8-8230-cab0e5f3c1bf','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-12.jpeg','Black','Plain Hoodie — 14 Colours — Black',11) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('32c51c6a-d609-5572-91d7-1729317a4539','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-13.jpeg','Baby Pink','Plain Hoodie — 14 Colours — Baby Pink',12) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('918f87c4-42ee-5814-97e8-058a430ae0d0','5a0610d1-b8cc-5e2e-b931-878969ab8841','5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-14.jpeg','Navy Blue','Plain Hoodie — 14 Colours — Navy Blue',13) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('03b529c4-add4-5061-8d59-2518e9d84fbc','4e2ba1c5-97ef-5f96-9a9a-bb473b87467e','Printed Collection — Option 01','A reference option in our Printed collection. Share this photo on WhatsApp to discuss your preferred print, colour, size, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('52ed0c92-2fc9-5ba8-b519-d405469bde20','03b529c4-add4-5061-8d59-2518e9d84fbc','03b529c4-add4-5061-8d59-2518e9d84fbc/photo-01.jpeg',NULL,'Printed Collection — Option 01',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('a4735dd2-2a41-5422-8859-ef014d0e1b79','4e2ba1c5-97ef-5f96-9a9a-bb473b87467e','Printed Collection — Option 02','A reference option in our Printed collection. Share this photo on WhatsApp to discuss your preferred print, colour, size, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('fa6ca079-ecab-5b9f-9b0c-660c2f83a4ef','a4735dd2-2a41-5422-8859-ef014d0e1b79','a4735dd2-2a41-5422-8859-ef014d0e1b79/photo-01.jpeg',NULL,'Printed Collection — Option 02',0) ON CONFLICT(path) DO NOTHING;
INSERT INTO public.products(id,category_id,name,description,care,price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours) VALUES ('7dd1690b-5e72-5d1c-ada1-83940d7cf962','4e2ba1c5-97ef-5f96-9a9a-bb473b87467e','Printed Collection — Option 03','A reference option in our Printed collection. Share this photo on WhatsApp to discuss your preferred print, colour, size, price and availability.','',NULL,'published',false,'unisex','hood','PKR',true,'[]'::jsonb) ON CONFLICT(id) DO NOTHING;
INSERT INTO public.product_images(id,product_id,path,color,alt,position) VALUES ('3fafdd7b-dd07-57c6-9535-8e6870da346f','7dd1690b-5e72-5d1c-ada1-83940d7cf962','7dd1690b-5e72-5d1c-ada1-83940d7cf962/photo-01.jpeg',NULL,'Printed Collection — Option 03',0) ON CONFLICT(path) DO NOTHING;


-- Anonymous email capture, private write function, administrator-only subscriber access.

CREATE TABLE IF NOT EXISTS public.newsletter_subscribers (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 email text NOT NULL UNIQUE CHECK(length(email)<=254),
 active boolean NOT NULL DEFAULT true,
 unsubscribe_token uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
 subscribed_at timestamptz NOT NULL DEFAULT now(),
 unsubscribed_at timestamptz
);
ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.newsletter_subscribers FROM anon,authenticated;
GRANT SELECT ON public.newsletter_subscribers TO authenticated;
DROP POLICY IF EXISTS subscribers_admin ON public.newsletter_subscribers;
CREATE POLICY subscribers_admin ON public.newsletter_subscribers FOR SELECT TO authenticated USING((SELECT private.is_admin()));
CREATE OR REPLACE FUNCTION private.subscribe_newsletter(p_email text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE normalized text:=lower(btrim(p_email));
BEGIN
 IF normalized IS NULL OR length(normalized)>254 OR normalized !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN RAISE EXCEPTION 'Enter a valid email address' USING ERRCODE='22023'; END IF;
 INSERT INTO public.newsletter_subscribers(email) VALUES(normalized)
 ON CONFLICT(email) DO UPDATE SET active=true,unsubscribed_at=NULL,subscribed_at=CASE WHEN NOT newsletter_subscribers.active THEN now() ELSE newsletter_subscribers.subscribed_at END;
END $$;
CREATE OR REPLACE FUNCTION public.subscribe_newsletter(p_email text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.subscribe_newsletter($1)$$;
CREATE OR REPLACE FUNCTION private.unsubscribe_newsletter(p_token uuid) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$UPDATE public.newsletter_subscribers SET active=false,unsubscribed_at=now() WHERE unsubscribe_token=p_token$$;
CREATE OR REPLACE FUNCTION public.unsubscribe_newsletter(p_token uuid) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.unsubscribe_newsletter($1)$$;
REVOKE ALL ON FUNCTION private.subscribe_newsletter(text),public.subscribe_newsletter(text),private.unsubscribe_newsletter(uuid),public.unsubscribe_newsletter(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.subscribe_newsletter(text),public.subscribe_newsletter(text),private.unsubscribe_newsletter(uuid),public.unsubscribe_newsletter(uuid) TO anon,authenticated;
CREATE TABLE IF NOT EXISTS public.newsletter_deliveries (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
 subscriber_id uuid NOT NULL REFERENCES public.newsletter_subscribers(id),product_name text NOT NULL,description text NOT NULL DEFAULT '',
 price_cents integer NOT NULL,status text NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','sending','sent','failed','skipped')),
 attempts integer NOT NULL DEFAULT 0,last_error text,provider_id text,sent_at timestamptz,locked_at timestamptz,
 next_attempt_at timestamptz NOT NULL DEFAULT now(),created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(product_id,subscriber_id)
);
ALTER TABLE public.newsletter_deliveries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.newsletter_deliveries FROM anon,authenticated;
GRANT SELECT ON public.newsletter_deliveries TO authenticated;
DROP POLICY IF EXISTS delivery_admin ON public.newsletter_deliveries;
CREATE POLICY delivery_admin ON public.newsletter_deliveries FOR SELECT TO authenticated USING((SELECT private.is_admin()));
CREATE INDEX IF NOT EXISTS newsletter_subscriber_idx ON public.newsletter_deliveries(subscriber_id);
NOTIFY pgrst,'reload schema';


ALTER TABLE public.products ADD COLUMN IF NOT EXISTS ingredients text NOT NULL DEFAULT '';
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS new_arrival boolean NOT NULL DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS storefront text NOT NULL DEFAULT 'legacy';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS expected_advance_cents bigint NOT NULL DEFAULT 0 CHECK(expected_advance_cents>=0);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS advance_paid_cents bigint NOT NULL DEFAULT 0 CHECK(advance_paid_cents>=0);
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_currency_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_currency_check CHECK(currency IN ('USD','PKR'));
CREATE INDEX IF NOT EXISTS hood_orders_storefront_idx ON public.orders(storefront,user_id,created_at);
CREATE TABLE IF NOT EXISTS private.hood_packaged_assets(path text PRIMARY KEY);
REVOKE ALL ON private.hood_packaged_assets FROM PUBLIC,anon,authenticated;


INSERT INTO private.hood_packaged_assets(path) VALUES ('f85b681f-13c3-54db-aeee-849641cd500f/photo-01.jpeg'),('ef70d7aa-ec9b-5738-b759-75cd66b247fb/photo-01.jpeg'),('8fdd5f05-7054-530f-a2b1-ef4ac46464b6/photo-01.jpeg'),('31d639a0-058a-5bc8-843a-6221d353d184/photo-01.jpeg'),('b21de1dc-6c15-5d14-bc3b-d7f4f5576d98/photo-01.jpeg'),('ddbb2e6f-8e5a-53a6-817d-1fd86ddf6da2/photo-01.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-01.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-02.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-03.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-04.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-05.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-06.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-07.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-08.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-09.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-10.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-11.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-12.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-13.jpeg'),('5a0610d1-b8cc-5e2e-b931-878969ab8841/photo-14.jpeg'),('03b529c4-add4-5061-8d59-2518e9d84fbc/photo-01.jpeg'),('a4735dd2-2a41-5422-8859-ef014d0e1b79/photo-01.jpeg'),('7dd1690b-5e72-5d1c-ada1-83940d7cf962/photo-01.jpeg') ON CONFLICT DO NOTHING;

-- Bank-transfer checkout and opt-in new-arrival notifications.
create table public.bank_transfer_settings (
 id boolean primary key default true check(id), bank_name text not null default '',
 account_title text not null default '', account_number text not null default '', iban text not null default '',
 instructions text not null default '', active boolean not null default false,
 updated_at timestamptz not null default now(),
 check(not active or (length(trim(bank_name))>0 and length(trim(account_title))>0 and (length(trim(account_number))>0 or length(trim(iban))>0)))
);
insert into public.bank_transfer_settings(id) values(true);
alter table public.bank_transfer_settings enable row level security;
grant select on public.bank_transfer_settings to anon,authenticated;
grant update on public.bank_transfer_settings to authenticated;
create policy bank_read on public.bank_transfer_settings for select to anon,authenticated using(true);
create policy bank_admin on public.bank_transfer_settings for update to authenticated using((select private.is_admin())) with check((select private.is_admin()));
alter table public.orders add column payment_method text not null default 'cod' check(payment_method in ('cod','bank_transfer'));
create table public.payment_submissions (
 id uuid primary key default gen_random_uuid(), order_id uuid not null unique references public.orders(id),
 user_id uuid not null references auth.users(id), transaction_id text not null check(length(trim(transaction_id)) between 3 and 100),
 screenshot_path text not null unique, bank_details jsonb not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 review_note text not null default '', reviewed_by uuid references auth.users(id), reviewed_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index payment_transaction_unique on public.payment_submissions(lower(trim(transaction_id)));
create index payment_submissions_user_idx on public.payment_submissions(user_id);
create index payment_submissions_reviewed_by_idx on public.payment_submissions(reviewed_by);
alter table public.payment_submissions enable row level security;
grant select on public.payment_submissions to authenticated;
create policy payment_read on public.payment_submissions for select to authenticated using(user_id=(select auth.uid()) or (select private.is_admin()));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('payment-receipts','payment-receipts',false,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;
create policy receipt_insert on storage.objects for insert to authenticated with check(bucket_id='payment-receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy receipt_read on storage.objects for select to authenticated using(bucket_id='payment-receipts' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select private.is_admin())));
create policy receipt_delete_unused on storage.objects for delete to authenticated using(bucket_id='payment-receipts' and (storage.foldername(name))[1]=(select auth.uid())::text and not exists(select 1 from public.payment_submissions p where p.screenshot_path=name));



ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS jazzcash_number text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS jazzcash_title text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS jazzcash_active boolean NOT NULL DEFAULT false;
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_number text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_title text NOT NULL DEFAULT '';
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS easypaisa_active boolean NOT NULL DEFAULT false;
ALTER TABLE public.bank_transfer_settings ADD COLUMN IF NOT EXISTS whatsapp_number text NOT NULL DEFAULT '923098670057';
ALTER TABLE public.payment_submissions ADD COLUMN IF NOT EXISTS contact_number text;
ALTER TABLE public.payment_submissions ADD COLUMN IF NOT EXISTS payment_provider text NOT NULL DEFAULT 'bank_alfalah' CHECK(payment_provider IN ('bank_alfalah','jazzcash','easypaisa'));
ALTER TABLE public.payment_submissions ADD COLUMN IF NOT EXISTS amount_cents bigint CHECK(amount_cents>0);
GRANT ALL ON public.bank_transfer_settings,public.payment_submissions,public.newsletter_subscribers,public.newsletter_deliveries TO service_role;


CREATE OR REPLACE FUNCTION private.hood_change_cart(p_variant_id uuid,p_quantity integer,p_operation text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=p_variant_id AND p.storefront='hood') THEN RAISE EXCEPTION 'HOOD product not found';END IF;
 IF p_operation<>'remove' AND EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=p_variant_id AND p.enquiry_only) THEN RAISE EXCEPTION 'Enquire on WhatsApp to confirm pricing and availability';END IF;
 PERFORM private.change_cart(p_variant_id,p_quantity,p_operation);
END $$;


CREATE OR REPLACE FUNCTION public.hood_add_to_cart(p_variant_id uuid,p_quantity integer) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_change_cart($1,$2,'add')$$;


CREATE OR REPLACE FUNCTION public.hood_set_cart_quantity(p_variant_id uuid,p_quantity integer) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_change_cart($1,$2,'set')$$;


CREATE OR REPLACE FUNCTION public.hood_remove_from_cart(p_variant_id uuid) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_change_cart($1,NULL,'remove')$$;


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
  ) AND p.storefront='hood' ORDER BY p.id FOR SHARE;
  PERFORM pv.id FROM public.product_variants pv JOIN public.cart_items ci ON ci.variant_id=pv.id
  WHERE ci.user_id=uid AND EXISTS(SELECT 1 FROM public.products p WHERE p.id=pv.product_id AND p.storefront='hood') ORDER BY pv.id FOR UPDATE OF pv;
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
  UPDATE public.product_variants pv SET stock=pv.stock-ci.quantity FROM public.cart_items ci WHERE ci.variant_id=pv.id AND ci.user_id=uid AND EXISTS(SELECT 1 FROM public.products p WHERE p.id=pv.product_id AND p.storefront='hood');
  INSERT INTO public.order_status_history(order_id,status) VALUES(new_order_id,'pending');
  DELETE FROM public.cart_items ci WHERE ci.user_id=uid AND EXISTS(SELECT 1 FROM public.product_variants v JOIN public.products p ON p.id=v.product_id WHERE v.id=ci.variant_id AND p.storefront='hood');
  RETURN QUERY SELECT new_order_id,new_order_number,subtotal+30000;
END $function$;


CREATE OR REPLACE FUNCTION public.hood_checkout_order(p_shipping jsonb,p_request_id uuid)
RETURNS TABLE(order_id uuid,order_number bigint,total_cents bigint) LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE placed record;
BEGIN
 SELECT * INTO placed FROM private.hood_checkout_impl(p_shipping,0,p_request_id);
 IF placed.total_cents>1000000 THEN RAISE EXCEPTION 'Orders above Rs. 10,000 require a 50%% advance via Bank Transfer or EasyPaisa';END IF;
 RETURN QUERY SELECT placed.order_id,placed.order_number,placed.total_cents;
END $$;


create or replace function private.hood_checkout_bank_transfer_v2(p_shipping jsonb,p_request_id uuid,p_transaction_id text,p_screenshot_path text,p_contact_number text,p_payment_provider text)
returns table(order_id uuid,order_number bigint,total_cents bigint) language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();settings public.bank_transfer_settings%rowtype;bank jsonb;placed record;phone text:=regexp_replace(trim(coalesce(p_contact_number,'')),'[ ()-]','','g');
begin
 if uid is null then raise exception 'Sign in to checkout' using errcode='28000';end if;
 if p_request_id is null then raise exception 'Checkout request ID is required';end if;
 insert into public.carts(user_id) values(uid) on conflict do nothing;
 perform 1 from public.carts c where c.user_id=uid for update;
 return query select o.id,o.order_number,o.total_cents from public.orders o join public.payment_submissions ps on ps.order_id=o.id where o.user_id=uid and o.request_id=p_request_id and o.payment_method='bank_transfer' and o.storefront='hood';
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
 select * into placed from private.hood_checkout_impl(jsonb_set(p_shipping,'{phone}',to_jsonb(phone)),0,p_request_id);
 if placed.total_cents>1000000 and p_payment_provider='jazzcash' then raise exception 'Advance orders require Bank Transfer or EasyPaisa';end if;
 update public.orders o set payment_method='bank_transfer',currency='PKR',expected_advance_cents=case when placed.total_cents>1000000 then (placed.total_cents+1)/2 else 0 end where o.id=placed.order_id;
 insert into public.payment_submissions(order_id,user_id,transaction_id,screenshot_path,bank_details,contact_number,payment_provider,amount_cents) values(placed.order_id,uid,trim(p_transaction_id),p_screenshot_path,bank,phone,p_payment_provider,case when placed.total_cents>1000000 then (placed.total_cents+1)/2 else placed.total_cents end);
 return query select placed.order_id,placed.order_number,placed.total_cents;
end $$;



CREATE OR REPLACE FUNCTION public.hood_checkout_bank_transfer_v2(p_shipping jsonb,p_request_id uuid,p_transaction_id text,p_screenshot_path text,p_contact_number text,p_payment_provider text) RETURNS TABLE(order_id uuid,order_number bigint,total_cents bigint) LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT * FROM private.hood_checkout_bank_transfer_v2($1,$2,$3,$4,$5,$6)$$;

create or replace function private.hood_update_order_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare current_status text;method text;payment text;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('pending','confirmed','processing','shipped','delivered','cancelled') then raise exception 'Invalid status';end if;
 select o.status,o.payment_method,o.payment_status into current_status,method,payment from public.orders o where o.id=p_order_id and o.storefront='hood' for update;
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

create or replace function private.hood_review_bank_payment(p_payment_id uuid,p_status text,p_note text)
returns void language plpgsql security definer set search_path='' as $$
declare submission public.payment_submissions%rowtype;ord public.orders%rowtype;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('approved','rejected') or length(coalesce(p_note,''))>1000 then raise exception 'Invalid review';end if;
 select o.* into ord from public.orders o where o.id=(select ps.order_id from public.payment_submissions ps where ps.id=p_payment_id) for update;
 select * into submission from public.payment_submissions where id=p_payment_id for update;
 if ord.id is null or ord.storefront<>'hood' then raise exception 'HOOD order not found';end if;
 if submission.id is null then raise exception 'Payment not found';end if;
 if submission.status<>'pending' then raise exception 'This payment has already been reviewed';end if;
 if ord.status in ('cancelled','delivered') or ord.payment_status<>'unpaid' then raise exception 'This order cannot receive a payment review';end if;
 if p_status='rejected' and length(trim(coalesce(p_note,'')))=0 then raise exception 'Explain why the payment was rejected';end if;
 update public.payment_submissions set status=p_status,review_note=trim(coalesce(p_note,'')),reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=p_payment_id;
 if p_status='approved' then
  update public.orders set advance_paid_cents=coalesce(submission.amount_cents,ord.total_cents) where id=ord.id;
  if coalesce(submission.amount_cents,ord.total_cents)>=ord.total_cents then perform private.hood_record_payment_status(submission.order_id,'paid');end if;
  if ord.status='pending' then perform private.hood_update_order_status(ord.id,'confirmed');end if;
 end if;
end $$;

create or replace function private.hood_record_payment_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare old_status text;order_status text;method text;
begin
 if auth.uid() is null or not private.is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_status is null or p_status not in ('unpaid','paid','refunded') then raise exception 'Invalid payment status';end if;
 select o.payment_status,o.status,o.payment_method into old_status,order_status,method from public.orders o where o.id=p_order_id and o.storefront='hood' for update;
 if not found then raise exception 'Order not found';end if;
 if old_status=p_status then return;end if;
 if p_status='paid' and order_status='cancelled' then raise exception 'Cannot mark a cancelled order as paid';end if;
 if p_status='paid' and method='bank_transfer' and not exists(select 1 from public.payment_submissions ps where ps.order_id=p_order_id and ps.status='approved') then raise exception 'Approve the payment proof in Payments first';end if;
 if p_status='refunded' and old_status<>'paid' then raise exception 'Only a paid order can be marked refunded';end if;
 if p_status='unpaid' and old_status='refunded' then raise exception 'A refunded payment cannot be marked unpaid';end if;
 update public.orders o set payment_status=p_status,advance_paid_cents=case when p_status='paid' then total_cents else advance_paid_cents end where o.id=p_order_id;
 insert into public.admin_notes(order_id,note) values(p_order_id,'Payment recorded as '||p_status||' by admin '||auth.uid()::text);
end $$;



CREATE OR REPLACE FUNCTION public.hood_set_order_status(p_order_id uuid,p_status text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_update_order_status($1,$2)$$;

CREATE OR REPLACE FUNCTION public.hood_set_payment_status(p_order_id uuid,p_status text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_record_payment_status($1,$2)$$;

CREATE OR REPLACE FUNCTION public.hood_review_bank_payment(p_payment_id uuid,p_status text,p_note text DEFAULT '') RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_review_bank_payment($1,$2,$3)$$;

create or replace function private.hood_resubmit_bank_payment(p_order_id uuid,p_transaction_id text,p_screenshot_path text) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();ord public.orders%rowtype; ps public.payment_submissions%rowtype;
begin
 if uid is null then raise exception 'Sign in first';end if;
 select * into ord from public.orders where id=p_order_id and user_id=uid and storefront='hood' for update;
 select * into ps from public.payment_submissions where order_id=p_order_id and user_id=uid and storefront='hood' for update;
 if ord.id is null or ps.id is null or ps.status<>'rejected' or ord.status='cancelled' or ord.payment_status<>'unpaid' then raise exception 'This order cannot receive a new payment proof';end if;
 if length(trim(coalesce(p_transaction_id,''))) not between 3 and 100 then raise exception 'Enter a valid transaction ID';end if;
 if p_screenshot_path not like uid::text||'/'||p_order_id::text||'/%' or not exists(select 1 from storage.objects where bucket_id='payment-receipts' and name=p_screenshot_path) then raise exception 'Upload the replacement screenshot first';end if;
 update public.payment_submissions set transaction_id=trim(p_transaction_id),screenshot_path=p_screenshot_path,status='pending',review_note='',reviewed_by=null,reviewed_at=null,updated_at=now() where id=ps.id;
end $$;
create or replace function private.hood_resubmit_bank_payment_v2(p_order_id uuid,p_transaction_id text,p_screenshot_path text,p_contact_number text) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();phone text:=regexp_replace(trim(coalesce(p_contact_number,'')),'[ ()-]','','g');
begin
 if uid is null then raise exception 'Sign in first';end if;
 if phone !~ '^\+?[0-9]{10,15}$' then raise exception 'Enter a valid contact number (10 to 15 digits)';end if;
 perform private.hood_resubmit_bank_payment(p_order_id,p_transaction_id,p_screenshot_path);
 update public.payment_submissions set contact_number=phone where order_id=p_order_id and user_id=uid;
 update public.orders set shipping_address=jsonb_set(shipping_address,'{phone}',to_jsonb(phone)) where id=p_order_id and user_id=uid;
end $$;

CREATE OR REPLACE FUNCTION public.hood_resubmit_bank_payment_v2(p_order_id uuid,p_transaction_id text,p_screenshot_path text,p_contact_number text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_resubmit_bank_payment_v2($1,$2,$3,$4)$$;

CREATE OR REPLACE FUNCTION private.hood_save_product(payload jsonb) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE pid uuid:=(payload->>'id')::uuid;cat uuid:=(payload->>'category_id')::uuid;inquiry boolean:=coalesce((payload->>'enquiry_only')::boolean,false);price integer; sale integer;entry jsonb;vid uuid;ids uuid[]:='{}';image_path_value text;counted integer;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE='42501';END IF;
 IF pid IS NULL OR length(btrim(coalesce(payload->>'name',''))) NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'Enter a product name';END IF;
 IF EXISTS(SELECT 1 FROM public.products p WHERE p.id=pid AND p.storefront<>'hood') THEN RAISE EXCEPTION 'This product belongs to another storefront';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.categories c WHERE c.id=cat AND c.storefront='hood') THEN RAISE EXCEPTION 'Choose a HOOD category';END IF;
 IF payload->>'status' NOT IN ('draft','published','archived') THEN RAISE EXCEPTION 'Invalid product status';END IF;
 IF jsonb_typeof(payload->'variants') IS DISTINCT FROM 'array' OR jsonb_typeof(payload->'images') IS DISTINCT FROM 'array' OR jsonb_array_length(payload->'images')>30 OR jsonb_array_length(payload->'variants')>500 THEN RAISE EXCEPTION 'Invalid product media or variants';END IF;
 IF inquiry THEN price:=NULL;sale:=NULL;
 ELSE
  price:=(payload->>'price_cents')::integer;sale:=nullif(payload->>'sale_price_cents','')::integer;
  IF price IS NULL OR price<=0 OR price>100000000 OR (sale IS NOT NULL AND (sale<=0 OR sale>=price)) THEN RAISE EXCEPTION 'Enter a valid product price';END IF;
  IF payload->>'status'='published' AND jsonb_array_length(payload->'variants')=0 THEN RAISE EXCEPTION 'Add complete size, colour and stock variants before publishing';END IF;
 END IF;
 IF payload->>'status'='published' AND (length(btrim(coalesce(payload->>'description','')))=0 OR jsonb_array_length(payload->'images')=0) THEN RAISE EXCEPTION 'Add a description and photograph before publishing';END IF;
 IF jsonb_typeof(coalesce(payload->'inquiry_colours','[]'::jsonb)) IS DISTINCT FROM 'array' OR jsonb_array_length(coalesce(payload->'inquiry_colours','[]'::jsonb))>100 THEN RAISE EXCEPTION 'Invalid enquiry colours';END IF;
 INSERT INTO public.products(id,category_id,name,description,care,price_cents,sale_price_cents,status,featured,department,storefront,currency,enquiry_only,inquiry_colours,ingredients,new_arrival)
 VALUES(pid,cat,btrim(payload->>'name'),coalesce(payload->>'description',''),coalesce(payload->>'care',''),price,sale,payload->>'status',coalesce((payload->>'featured')::boolean,false),coalesce(payload->>'department','unisex'),'hood','PKR',inquiry,coalesce(payload->'inquiry_colours','[]'::jsonb),coalesce(payload->>'ingredients',''),coalesce((payload->>'new_arrival')::boolean,false))
 ON CONFLICT(id) DO UPDATE SET category_id=excluded.category_id,name=excluded.name,description=excluded.description,care=excluded.care,price_cents=excluded.price_cents,sale_price_cents=excluded.sale_price_cents,status=excluded.status,featured=excluded.featured,department=excluded.department,enquiry_only=excluded.enquiry_only,inquiry_colours=excluded.inquiry_colours,ingredients=excluded.ingredients,new_arrival=excluded.new_arrival;
 FOR entry IN SELECT * FROM jsonb_array_elements(payload->'variants') LOOP
  IF length(btrim(coalesce(entry->>'color','')))=0 OR length(btrim(coalesce(entry->>'size','')))=0 THEN RAISE EXCEPTION 'Each variant needs a colour and size';END IF;
  vid:=coalesce(nullif(entry->>'id','')::uuid,gen_random_uuid());ids:=array_append(ids,vid);
  INSERT INTO public.product_variants(id,product_id,color,color_hex,size,stock,active)
  VALUES(vid,pid,btrim(entry->>'color'),coalesce(entry->>'color_hex','#222222'),btrim(entry->>'size'),coalesce((entry->>'stock')::integer,0),true)
  ON CONFLICT(id) DO UPDATE SET color=excluded.color,color_hex=excluded.color_hex,size=excluded.size,stock=excluded.stock,active=true WHERE product_variants.product_id=pid;
  GET DIAGNOSTICS counted=ROW_COUNT;IF counted<>1 THEN RAISE EXCEPTION 'Variant belongs to another product';END IF;
 END LOOP;
 UPDATE public.product_variants SET active=false,stock=0 WHERE product_id=pid AND NOT(id=ANY(ids));
 FOR entry IN SELECT * FROM jsonb_array_elements(payload->'images') LOOP
  image_path_value:=entry->>'path';
  IF image_path_value IS NULL OR image_path_value NOT LIKE pid::text||'/%' OR NOT (EXISTS(SELECT 1 FROM private.hood_packaged_assets a WHERE a.path=image_path_value) OR EXISTS(SELECT 1 FROM storage.objects s WHERE s.bucket_id='product-images' AND s.name=image_path_value)) THEN RAISE EXCEPTION 'Upload a valid product photograph';END IF;
 END LOOP;
 DELETE FROM public.product_images WHERE product_id=pid;
 INSERT INTO public.product_images(product_id,path,color,alt,position)
 SELECT pid,e->>'path',nullif(e->>'color',''),coalesce(e->>'alt',payload->>'name'),n::integer-1 FROM jsonb_array_elements(payload->'images') WITH ORDINALITY a(e,n);
 RETURN pid;
END $$;
CREATE OR REPLACE FUNCTION public.hood_save_product(payload jsonb) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_save_product($1)$$;
CREATE OR REPLACE FUNCTION private.hood_delete_product(p_product_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE='42501';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.products WHERE id=p_product_id AND storefront='hood') THEN RAISE EXCEPTION 'HOOD product not found';END IF;
 SELECT public.delete_product(p_product_id) INTO result;RETURN result;
END $$;
CREATE OR REPLACE FUNCTION public.hood_delete_product(p_product_id uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_delete_product($1)$$;
CREATE OR REPLACE FUNCTION private.hood_queue_new_arrival() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.storefront='hood' AND NEW.status='published' AND NEW.new_arrival AND NOT NEW.enquiry_only AND NEW.effective_price_cents IS NOT NULL AND (TG_OP='INSERT' OR OLD.status IS DISTINCT FROM 'published' OR NOT OLD.new_arrival) THEN
  INSERT INTO public.newsletter_deliveries(product_id,subscriber_id,product_name,description,price_cents)
  SELECT NEW.id,s.id,NEW.name,NEW.description,NEW.effective_price_cents FROM public.newsletter_subscribers s WHERE s.active ON CONFLICT(product_id,subscriber_id) DO NOTHING;
 END IF;RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS hood_queue_new_arrival ON public.products;
CREATE TRIGGER hood_queue_new_arrival AFTER INSERT OR UPDATE OF status,new_arrival ON public.products FOR EACH ROW EXECUTE FUNCTION private.hood_queue_new_arrival();
REVOKE ALL ON FUNCTION private.hood_queue_new_arrival() FROM PUBLIC,anon,authenticated;
-- The support service already has a single auth-linked conversation; read receipts are separate.
CREATE TABLE public.hood_support_read_state(user_id uuid NOT NULL REFERENCES auth.users(id),conversation_id uuid NOT NULL REFERENCES public.support_requests(id) ON DELETE CASCADE,read_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(user_id,conversation_id));
ALTER TABLE public.hood_support_read_state ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE ON public.hood_support_read_state TO authenticated;
CREATE POLICY hood_support_read_own ON public.hood_support_read_state TO authenticated USING(user_id=(SELECT auth.uid())) WITH CHECK(user_id=(SELECT auth.uid()));
CREATE OR REPLACE FUNCTION private.hood_mark_support_read(p_conversation_id uuid,p_admin boolean DEFAULT false) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required';END IF;
 IF p_admin AND NOT private.is_admin() THEN RAISE EXCEPTION 'Admin access required';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.support_requests WHERE id=p_conversation_id AND (user_id=auth.uid() OR (p_admin AND private.is_admin()))) THEN RAISE EXCEPTION 'Conversation not found';END IF;
 INSERT INTO public.hood_support_read_state(user_id,conversation_id) VALUES(auth.uid(),p_conversation_id) ON CONFLICT(user_id,conversation_id) DO UPDATE SET read_at=now();
END $$;
CREATE OR REPLACE FUNCTION public.hood_mark_support_read(p_conversation_id uuid,p_admin boolean DEFAULT false) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$SELECT private.hood_mark_support_read($1,$2)$$;

create table public.hood_instagram_reels (
  id uuid primary key default gen_random_uuid(),
  hood_instagram_url text not null check (hood_instagram_url ~* '^https?://(www\.)?instagram\.com/reel/[a-z0-9_-]+/?(\?.*)?$'),
  username text not null default 'hood_pending' check (username ~ '^[A-Za-z0-9._]{1,30}$'),
  profile_image text check (profile_image is null or profile_image ~ '^https://'),
  thumbnail_url text check (thumbnail_url is null or thumbnail_url ~ '^https://'),
  category text not null default '' check (length(category) <= 120),
  shop_url text check (shop_url is null or shop_url ~ '^https://' or (left(shop_url, 1) = '/' and left(shop_url, 2) <> '//')),
  product_id uuid references public.products(id) on delete set null,
  is_active boolean not null default true,
  display_order integer not null default 0 check (display_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index hood_instagram_reels_active_order_idx
  on public.hood_instagram_reels(is_active, display_order, created_at);
create trigger hood_instagram_reels_updated
  before update on public.hood_instagram_reels
  for each row execute function private.touch_updated_at();

alter table public.hood_instagram_reels enable row level security;
revoke all on public.hood_instagram_reels from anon, authenticated;
grant select on public.hood_instagram_reels to anon, authenticated;
grant insert, update, delete on public.hood_instagram_reels to authenticated;
grant all on public.hood_instagram_reels to service_role;

create policy hood_instagram_reels_active_read
  on public.hood_instagram_reels for select to anon, authenticated
  using (is_active or (select private.is_admin()));

create policy hood_instagram_reels_admin_write
  on public.hood_instagram_reels for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
alter table public.hood_instagram_reels
  add column media_id text,
  add column media_url text,
  add column media_type text,
  add column caption text not null default '',
  add column published_at timestamptz,
  add column view_count bigint check (view_count is null or view_count >= 0),
  add column like_count bigint check (like_count is null or like_count >= 0),
  add column comment_count bigint check (comment_count is null or comment_count >= 0);

create unique index hood_instagram_reels_media_id_unique_idx
  on public.hood_instagram_reels(media_id);
drop index if exists public.hood_instagram_reels_thumbnail_unique_idx;

create table public.hood_instagram_feed_settings (
  id boolean primary key default true check (id),
  username text not null default 'hood_pending' check (username ~ '^[A-Za-z0-9._]{1,30}$'),
  profile_url text not null default 'https://www.instagram.com/' check (profile_url ~ '^https://www\.instagram\.com/'),
  reels_to_display integer not null default 10 check (reels_to_display between 1 and 50),
  is_enabled boolean not null default false,
  autoplay_enabled boolean not null default true,
  autoplay_interval_seconds integer not null default 3 check (autoplay_interval_seconds between 3 and 10),
  desktop_cards integer not null default 5 check (desktop_cards between 4 and 5),
  mobile_cards numeric(3,2) not null default 1.20 check (mobile_cards between 1 and 2),
  last_synced_at timestamptz,
  updated_at timestamptz not null default now()
);

insert into public.hood_instagram_feed_settings(id) values(true) on conflict(id) do nothing;
create trigger hood_instagram_feed_settings_updated
  before update on public.hood_instagram_feed_settings
  for each row execute function private.touch_updated_at();

alter table public.hood_instagram_feed_settings enable row level security;
revoke all on public.hood_instagram_feed_settings from anon, authenticated;
grant select on public.hood_instagram_feed_settings to anon, authenticated;
grant update on public.hood_instagram_feed_settings to authenticated;
grant all on public.hood_instagram_feed_settings to service_role;
create policy hood_instagram_feed_settings_read on public.hood_instagram_feed_settings
  for select to anon, authenticated using (is_enabled or (select private.is_admin()));
create policy hood_instagram_feed_settings_admin_update on public.hood_instagram_feed_settings
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create table public.hood_instagram_private_connection (
  id boolean primary key default true check (id),
  hood_instagram_user_id text not null,
  username text not null,
  access_token text not null,
  token_expires_at timestamptz not null,
  profile_image_url text,
  connected_at timestamptz not null default now(),
  last_synced_at timestamptz
);
create table public.hood_instagram_oauth_states (
  state text primary key,
  admin_user_id uuid not null references auth.users(id) on delete cascade,
  redirect_origin text not null,
  expires_at timestamptz not null
);
alter table public.hood_instagram_private_connection enable row level security;
alter table public.hood_instagram_oauth_states enable row level security;
revoke all on public.hood_instagram_private_connection, public.hood_instagram_oauth_states from public, anon, authenticated;
grant all on public.hood_instagram_private_connection, public.hood_instagram_oauth_states to service_role;
create table private.newsletter_worker_config(id boolean primary key default true check(id),token text not null default replace(gen_random_uuid()::text||gen_random_uuid()::text,'-',''));
insert into private.newsletter_worker_config(id) values(true);
revoke all on private.newsletter_worker_config from public,anon,authenticated;
create function public.verify_newsletter_worker(p_token text) returns boolean language sql security definer set search_path='' as $$select exists(select 1 from private.newsletter_worker_config where token=p_token)$$;
revoke all on function public.verify_newsletter_worker(text) from public,anon,authenticated;
grant execute on function public.verify_newsletter_worker(text) to service_role;
create function public.claim_newsletter_deliveries() returns table(id uuid,product_id uuid,email text,unsubscribe_token uuid,product_name text,description text,price_cents integer,attempts integer) language plpgsql security definer set search_path='' as $$
begin
 update public.newsletter_deliveries d set status='skipped' where d.status in ('queued','failed','sending') and not exists(select 1 from public.newsletter_subscribers s where s.id=d.subscriber_id and s.active);
 return query with picked as (
  select d.id from public.newsletter_deliveries d where ((d.status in ('queued','failed') and d.next_attempt_at<=now()) or (d.status='sending' and d.locked_at<now()-interval '10 minutes')) and d.attempts<8 order by d.created_at for update skip locked limit 25
 ), claimed as (
  update public.newsletter_deliveries d set status='sending',attempts=d.attempts+1,locked_at=now() from picked p where d.id=p.id returning d.*
 ) select c.id,c.product_id,s.email,s.unsubscribe_token,c.product_name,c.description,c.price_cents,c.attempts from claimed c join public.newsletter_subscribers s on s.id=c.subscriber_id where s.active;
end $$;
revoke all on function public.claim_newsletter_deliveries() from public,anon,authenticated;
grant execute on function public.claim_newsletter_deliveries() to service_role;

grant all on public.newsletter_subscribers,public.newsletter_deliveries,public.payment_submissions,public.bank_transfer_settings to service_role;


-- Public aggregate counts only: no customer names, IDs or order details.
create table public.product_purchase_stats (
  product_id uuid primary key references public.products(id) on delete cascade,
  purchaser_count bigint not null default 0 check (purchaser_count >= 0),
  updated_at timestamptz not null default now()
);
alter table public.product_purchase_stats enable row level security;
revoke all on public.product_purchase_stats from public, anon, authenticated;
grant select on public.product_purchase_stats to anon, authenticated;
create policy published_product_purchase_stats_read
on public.product_purchase_stats for select to anon, authenticated
using (exists (select 1 from public.products p where p.id = product_id and p.status = 'published'));

-- Trigger-only function in a non-exposed schema. Checkout RLS remains unchanged.
create function private.sync_product_purchase_stats()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if pg_catalog.pg_trigger_depth() < 1 then
    raise exception 'This function is only available to database triggers';
  end if;
  -- Serialize summary refreshes so concurrent checkouts cannot overwrite newer counts.
  perform pg_catalog.pg_advisory_xact_lock(54117, 281);
  insert into public.product_purchase_stats(product_id, purchaser_count)
  select p.id, count(distinct o.user_id) filter (
    where o.status <> 'cancelled' and o.payment_status <> 'refunded'
      and (o.payment_status = 'paid' or o.status = 'delivered')
  )
  from public.products p
  left join public.product_variants v on v.product_id = p.id
  left join public.order_items oi on oi.variant_id = v.id
  left join public.orders o on o.id = oi.order_id
  group by p.id
  on conflict (product_id) do update
    set purchaser_count = excluded.purchaser_count, updated_at = now()
    where public.product_purchase_stats.purchaser_count is distinct from excluded.purchaser_count;
  return null;
end;
$$;
revoke all on function private.sync_product_purchase_stats() from public, anon, authenticated;
create trigger product_purchase_stats_after_orders
  after insert or update or delete on public.orders
  for each statement execute function private.sync_product_purchase_stats();
create trigger product_purchase_stats_after_items
  after insert or update or delete on public.order_items
  for each statement execute function private.sync_product_purchase_stats();
create trigger product_purchase_stats_after_variant_reassignment
  after update of product_id on public.product_variants
  for each statement execute function private.sync_product_purchase_stats();

insert into public.product_purchase_stats(product_id, purchaser_count)
select p.id, count(distinct o.user_id) filter (
  where o.status <> 'cancelled' and o.payment_status <> 'refunded'
    and (o.payment_status = 'paid' or o.status = 'delivered')
)
from public.products p
left join public.product_variants v on v.product_id = p.id
left join public.order_items oi on oi.variant_id = v.id
left join public.orders o on o.id = oi.order_id
 group by p.id;


CREATE TABLE public.hood_customers(user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.hood_customers ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT ON public.hood_customers TO authenticated;
CREATE POLICY hood_customers_read ON public.hood_customers FOR SELECT TO authenticated USING(user_id=(SELECT auth.uid()) OR (SELECT private.is_admin()));
CREATE POLICY hood_customers_join ON public.hood_customers FOR INSERT TO authenticated WITH CHECK(user_id=(SELECT auth.uid()));
create table public.hood_love_gallery_photos (
 id uuid primary key default gen_random_uuid(),
 source_bucket text not null default 'hood-love-gallery' check(source_bucket in ('hood-love-gallery','product-images')),
 image_path text not null check(length(image_path) between 1 and 512 and image_path not like '%..%' and left(image_path,1)<>'/'),
 alt text not null default 'Maison Élan clothing' check(length(alt)<=240),
 caption text not null default '' check(length(caption)<=180),
 display_order integer not null default 0 check(display_order>=0),
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(source_bucket,image_path)
);
create index hood_love_gallery_active_order_idx on public.hood_love_gallery_photos(is_active,display_order,created_at,id);
create trigger hood_love_gallery_updated before update on public.hood_love_gallery_photos for each row execute function private.touch_updated_at();
alter table public.hood_love_gallery_photos enable row level security;
revoke all on public.hood_love_gallery_photos from anon,authenticated;
grant select on public.hood_love_gallery_photos to anon,authenticated;
grant insert,update,delete on public.hood_love_gallery_photos to authenticated;
grant all on public.hood_love_gallery_photos to service_role;
create policy hood_love_gallery_read on public.hood_love_gallery_photos for select to anon,authenticated using(is_active or (select private.is_admin()));
create policy hood_love_gallery_admin_insert on public.hood_love_gallery_photos for insert to authenticated with check((select private.is_admin()));
create policy hood_love_gallery_admin_update on public.hood_love_gallery_photos for update to authenticated using((select private.is_admin())) with check((select private.is_admin()));
create policy hood_love_gallery_admin_delete on public.hood_love_gallery_photos for delete to authenticated using((select private.is_admin()));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('hood-love-gallery','hood-love-gallery',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy hood_love_gallery_storage_insert on storage.objects for insert to authenticated with check(bucket_id='hood-love-gallery' and (storage.foldername(name))[1]='gallery' and (select private.is_admin()));
create policy hood_love_gallery_storage_read on storage.objects for select to authenticated using(bucket_id='hood-love-gallery' and (select private.is_admin()));
create policy hood_love_gallery_storage_delete on storage.objects for delete to authenticated using(bucket_id='hood-love-gallery' and (select private.is_admin()));

DO $privileges$
DECLARE f record;
BEGIN
 FOR f IN SELECT p.oid::regprocedure AS signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private') AND p.proname LIKE 'hood_%' AND p.prorettype<>'trigger'::regtype LOOP
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
  EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',f.signature);
 END LOOP;
END $privileges$;
NOTIFY pgrst,'reload schema';
COMMIT;

