-- Repair HOOD-only Instagram column names; preserves connection data.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='hood_instagram_reels' AND column_name='hood_instagram_url') THEN
 ALTER TABLE public.hood_instagram_reels RENAME COLUMN hood_instagram_url TO instagram_url;
 END IF;
 IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='hood_instagram_private_connection' AND column_name='hood_instagram_user_id') THEN
 ALTER TABLE public.hood_instagram_private_connection RENAME COLUMN hood_instagram_user_id TO instagram_user_id;
 END IF;
END $$;
ALTER TABLE public.hood_instagram_reels DROP CONSTRAINT IF EXISTS hood_instagram_reels_hood_instagram_url_check;
ALTER TABLE public.hood_instagram_reels DROP CONSTRAINT IF EXISTS hood_instagram_reels_instagram_url_check;
ALTER TABLE public.hood_instagram_reels ADD CONSTRAINT hood_instagram_reels_instagram_url_check CHECK (instagram_url ~* '^https://(www[.])?instagram[.]com/(reel|p)/[a-z0-9_-]+/?([?].*)?$');
NOTIFY pgrst, 'reload schema';
