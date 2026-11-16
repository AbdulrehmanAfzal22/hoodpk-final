Current store requirements and activation instructions: see THE_HOOD_SETUP.md first. The earlier zero-delivery policy is superseded by the required hood_store_setup.sql update.

# Cloth-web integration update

Maison Élan homepage, layout and styles are retained. Checkout, authentication and admin controls now expose Bella-compatible integrations.

## Included
- Email/password signup/login, Google OAuth callback, confirmation and password recovery.
- PKR cash-on-delivery and manual JazzCash / Bank Alfalah transfers, private receipt uploads, signed viewing links, rejected-proof resubmission and admin payment review.
- Real newsletter signup, unsubscribe route, admin subscribers/delivery overview, new-arrival queue and Resend email worker.
- Sale pricing, catalog save/delete fixes, Instagram services and gallery administration.
- Netlify SPA routing.

## Activation still required
No hosted database migrations or deployments were performed. Live payment, email, OAuth and Instagram flows have not been verified.

The frontend retains cloth's Supabase project oapkgdvsnpakpackmgcs. Override with VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY as needed; never expose service-role credentials to Vite.

1. Run npm ci then npm run dev. Build with npm run build.
2. Inspect the target migration history, then apply ONLY missing files from supabase/migrations in filename order. Existing migrations must not be replayed blindly. Validate the source SQL against the target schema before deployment.
3. Apply supabase/updates/product_purchase_stats.sql if using aggregate purchase counts. Bella promotional purchase offsets and cosmetic demo mappings are disabled.
4. Deploy instagram-feed, delete-product and new-arrival-emails. The newsletter function checks a private worker token itself, with gateway JWT verification disabled in config.toml for cron requests. Its scheduled URL now targets cloth's project.
5. Configure RESEND_API_KEY, EMAIL_FROM (verified sender) and SITE_URL (cloth HTTPS origin) as worker secrets. Do not copy Bella credentials.
6. Enter and activate the store's payment account details at /admin/payments. These are manual transfers reviewed by an administrator, not an automatic charging gateway. Bella bank details were not copied.
7. Enable Google OAuth in cloth's Auth settings and configure its client. Allow /auth/callback and /reset-password for the production store and http://localhost:4173 during development. Email redirects use the requesting browser origin; configure the production Auth Site URL/allowlist before launch.
8. Configure the intended Instagram account at /admin/instagram-reels. The original clothing archive already contained Bella Instagram wording; verify its account before publishing.
9. Gallery management is at /admin/love-gallery. Homepage gallery placement remains for the UI update.

## Verification
Vite production build passed. All 50 Node tests passed, including receipt validation/upload, payment options, sale calculations and auth callbacks. Hosted database behavior, provider settings and delivery remain unverified. No real orders, payments or emails were created.
