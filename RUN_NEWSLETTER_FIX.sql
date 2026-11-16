-- Anonymous email capture, private write function, administrator-only subscriber access.
BEGIN;
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
COMMIT;
