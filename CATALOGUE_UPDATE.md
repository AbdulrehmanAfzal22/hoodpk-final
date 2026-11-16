Latest change: original pre-catalogue hero photograph restored. The 01.55.46 ZIP matches the existing fourteen hoodie images byte-for-byte; no duplicate listings were created. A dedicated homepage Hoodies section now shows all fourteen colour cards, each opening the corresponding selected colour on the product page.

# Uploaded catalogue replacement

## Active catalogue in this project
The website now uses ONLY the supplied enquiry catalogue by default (`VITE_CATALOG_SOURCE=uploaded`). It does not load old Legacy/Sunnah products or categories. All photo assets are bundled locally, so the catalogue works without a database import or external image host.

- First ZIP (01.30.20): 6 bundle reference listings in Combo Deals / Bundles. The number of items included in a bundle has not been assumed.
- Second ZIP (01.28.59): 1 Plain Hoodie listing with 14 colour choices and corresponding photographs.
- Third ZIP (01.28.35): 3 reference listings in Printed, as requested.
- Total: 10 listings, 23 original photographs, 14 hoodie colour choices.

Exact colour list: Brown, Orange, Yellow, Purple, Red, Hot Pink, Lilac, Navy Green, Baby Blue, White, Light grey, Black, Baby Pink, Navy Blue.

The photographs are unaltered. Colour-to-image assignment is visual, not ZIP ordering: Brown is the brown hoodie photo; Baby Pink the pale-pink photo; Black the black photo, etc. The catalogue manifest retains source filenames and SHA-256 hashes for all 23 files.

## Enquiries, as requested
All listings show Price on request. Product pages offer preferred size (free text, optional), enquiry quantity, hoodie colour selection and a WhatsApp message containing the product and page URL. No prices, selectable stock-backed sizes, stock quantities, bundle contents or best-seller claims were invented. Cart/Buy Now and review submission are hidden for these enquiry products.

## Old data and connected database
Read-only inspection showed cloth-web's database contains both Legacy and Sunnah storefront records. No live database record has been deleted, archived or changed. The updated project excludes those catalogues and old direct product URLs from THE HOOD.PK's storefront. Customer/order history is preserved.

## Optional database persistence later
The default uploaded catalogue requires no database write. To manage these listings online later, deploy the updated code/assets together with `supabase/updates/hood_uploaded_catalogue.sql`, then set VITE_CATALOG_SOURCE=supabase. This optional import adds the separate hood storefront, enquiry-only support, scoped categories and the 10 enquiries. It does not delete or steal another storefront's categories. Its exact names/slugs are normalised to the seven display categories in the frontend.

Do not switch the source setting before importing. Online product/category editing is intentionally blocked in uploaded-source mode. To enable priced checkout later, confirm price, size/stock variants and material details, then convert the enquiry in the database/admin after completing the original checkout integration setup. Optional persistence SQL is included but has NOT been applied to the hosted project.

The original fixed-delivery and advance-payment setup is unchanged for future priced products. No WhatsApp message, newsletter email or real order was sent during this update.

## Verification
All packaged source images are checked byte-for-byte; all hoodie colour galleries resolve to their own single photograph. Tests check category allocation, no invented prices/variants and exclusion of legacy data. Production build passes. All 58 automated tests pass, including the isolated optional-import database test.
