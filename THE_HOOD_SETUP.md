Latest catalogue update: read CATALOGUE_UPDATE.md first. The supplied photos are now packaged as enquiry-only listings; earlier requests for product images are superseded by this import.

# THE HOOD.PK — black and red store

## Completed in this project
- Black/red palette; top and bottom waves on Why Choose Us; wavy newsletter/footer; original supplied logo.
- Seven homepage category destinations: Customised Hoodies, Printed, Plain Hoodies, Zipper Hoodies, Sweatshirts, T-Shirts, Combo Deals / Bundles.
- Promotional hero, Shop by Category, Best Sellers, New Arrivals, Combo Deals, customisation, Bulk Orders, approved Customer Reviews, existing Instagram feed, newsletter.
- WhatsApp +92 309 8670057 on every route, customisation links on Customised Hoodies and T-Shirts and a bulk enquiry CTA. Messages include selected product/colour/size/quantity and URL. A standard message is used because no exact message text was supplied.
- Existing product image gallery, descriptions, size/colour/quantity selection and cart editing; new Buy Now action shares the selected variant and quantity.
- PKR totals with fixed Rs. 300 delivery. Cash on Delivery up to Rs. 10,000 total. Above Rs. 10,000 total (including delivery), 50% advance via Bank Transfer / EasyPaisa and the remainder due on delivery. Advance rounds up to one paisa.
- Exact supplied About Us, customisation text and seven FAQs, with Contact, Return/Exchange and Size Guide pages.
- No made-up printed designs, stock, reviews, best-seller figures or universal size measurements.

## Required backend update before using this checkout
First inspect the target project's migration history and apply missing base migrations in filename order, as described in INTEGRATION_SETUP.md. Then apply supabase/updates/hood_store_setup.sql to THAT clothing project. This adds the seven categories, EasyPaisa settings, delivery/advance enforcement, receipt amount and advance/balance tracking. The update was exercised in an isolated PostgreSQL-compatible test database; it has NOT been applied to the hosted project.

Do not enable the new checkout against the old backend functions: frontend and backend policy must be deployed together. The update deliberately rejects full COD above the threshold, preserves cart/stock on rejected checkout and never marks a 50% deposit as fully paid.

In /admin/payments enter your actual receiving bank and/or EasyPaisa account, and enable the method. The WhatsApp number is a contact number only; it is NOT assumed to be a receiving EasyPaisa account. Old inherited Bella receiving-account defaults are removed by the setup script only when they match the known source defaults. No unrelated configured account is cleared.

After verifying an advance receipt, the order becomes confirmed while its payment remains unpaid for the outstanding balance. Admin Orders shows that balance; record Paid only after collecting the remainder. Rejecting a receipt preserves the customer's correction/resubmission flow.

## Content you still need to supply
- Product photographs, prices, stock, sizes, colours and printed designs: add/publish in /admin/products and assign one of the seven categories.
- Best Sellers: tick the Best Sellers / featured checkbox for the products you want in that edit.
- Combo Deals: create bundle products under Combo Deals / Bundles. Bundle totals use their configured product price; they are not automatic discounts across independent items.
- Category photographs: upload through category management; until then the homepage uses clean clothing icons instead of stock photos that imply a product.
- Exact garment size measurements: the Size Guide currently explains how to measure and links to WhatsApp. It does not invent a size chart.
- Verified Instagram profile URL and account authorization: set VITE_INSTAGRAM_URL and connect the account in /admin/instagram-reels. The original feed integration requires its existing backend function/secrets.
- Newsletter sender/provider configuration is still required as described in INTEGRATION_SETUP.md.

## Run and verify
npm ci
npm run dev
npm test
npm run build

Validation: 53 automated tests passed, including isolated database checks for shipping, threshold boundary, COD rollback, EasyPaisa deposit, approval without full-payment mislabelling, admin balance collection, idempotent retry and authorization. Markup checks passed for seven categories/FAQs, wave boundaries, newsletter, policy links, Buy Now and encoded WhatsApp messages. Production build passed. Browser screenshot verification remains unavailable in this environment.

Deployment: Netlify uses included netlify.toml. No live deployment, real order, payment, WhatsApp message or email was performed.
