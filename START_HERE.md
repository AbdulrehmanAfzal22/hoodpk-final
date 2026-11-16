# THE HOOD.PK — backend activation package

This package contains the fully prepared frontend/backend connection, but it is NOT activated on the live project yet. Read BACKEND_APPROVAL.md before deployment.

The one complete database update is RUN_BACKEND_SETUP.sql (also in supabase/updates/hood_backend_complete.sql). Do not run the older update scripts alongside it: this complete update replaces their individual activation steps.

After the full SQL update is approved and applied to cloth-web, deploy the two new Edge Functions: hood-instagram-feed and hood-new-arrival-emails. Their source is in supabase/functions. The existing other-storefront endpoints are preserved.

The frontend now reads HOOD products/categories from Supabase and uses HOOD-specific cart, checkout, admin-save and payment RPCs. Do not deploy this new frontend before the complete database upgrade: the required HOOD tables/RPCs do not exist yet.

Local commands: npm ci; npm test; npm run build; npm run dev.

Current catalogue: 10 enquiry listings, 23 supplied photos, 14 hoodie colours, WhatsApp +92 309 8670057. No product price, size or stock was invented. No fictional reviews are displayed.
