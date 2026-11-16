# Prepared live change requiring approval

## Current status
Automatic approval review rejected the full production migration. The stated reason was that it alters shared product/order schemas and constraints, imports catalogue data, adds privileged payment/admin functions and changes access controls, and that the general build request did not narrowly authorize that cross-storefront scope.

No part of the full migration was applied. A separate, smaller newsletter-only request again returned an expired service confirmation. The live newsletter function therefore remains missing. The backend is NOT claimed to be live or fully activated.

## Exact change to approve
Target: existing Supabase project cloth-web, reference oapkgdvsnpakpackmgcs.
Artifact: RUN_BACKEND_SETUP.sql, identical to supabase/updates/hood_backend_complete.sql.

The update:
- Adds a HOOD storefront value to the shared product/category schema, allows null product prices ONLY for enquiry-only products, and adds the sale/effective-price, material and new-arrival fields used by this app.
- Imports the 7 HOOD-scoped categories and 10 enquiry records, with 23 media references. Supplied photographs remain packaged local assets; admin uploads use Supabase Storage.
- Adds the order storefront/advance fields and permits PKR as well as USD. Existing order currency defaults and the other storefront's checkout functions are preserved.
- Adds blank/inactive bank and EasyPaisa settings, private receipt storage, receipt review, partial-advance tracking and dedicated HOOD cart/checkout/status RPCs.
- Adds admin-only HOOD product-save/delete RPCs, customer membership, gallery administration and support read state.
- Adds newsletter capture/unsubscribe and admin-only subscription/delivery access. It does not send any emails as part of the update.
- Creates separate HOOD Instagram integration tables; no existing Instagram connection is overwritten.
- Adds new function grants and row-level policies for these features, then reloads the API schema cache.

These changes do not delete or archive the 1 Legacy and 342 Sunnah products found during the audit. They do not reassign their categories or alter their product prices. The isolated test verifies preservation of another storefront's cart item and stock during HOOD checkout.

## Activation after approval
1. Apply the complete SQL update once, using the confirmed Supabase migration flow. Do not deploy the connected frontend until this succeeds.
2. Deploy hood-instagram-feed and hood-new-arrival-emails, preserving the existing endpoints. JWT gateway verification is disabled only because those functions authenticate privileged actions internally (admin session or private worker token); the feed itself is public.
3. Enter actual receiving accounts under /admin/payments. The WhatsApp number is not automatically used as an EasyPaisa account.
4. Configure HOOD_META_APP_ID / HOOD_META_APP_SECRET and authorize the actual Instagram account, or supply HOOD_INSTAGRAM_ACCESS_TOKEN. Do not copy another store's token.
5. Configure HOOD_RESEND_API_KEY, HOOD_EMAIL_FROM and HOOD_SITE_URL before campaign delivery. Signup capture itself does not need an email provider.
6. Enter confirmed prices, size/colour variants and stock before turning enquiry listings into online checkout products.

## Validation
60 automated tests passed and the production build passed. The new full-backend regression applies the complete SQL to an isolated PostgreSQL-compatible fixture and exercises newsletter capture, admin authorization, enquiry editing, conversion to a priced test variant, cross-store cart rejection, over-threshold COD rollback, Rs. 300 delivery, EasyPaisa advance approval and balance collection. This is local validation, not evidence that the production upgrade was applied.
